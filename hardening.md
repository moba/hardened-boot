# Laptop Hardening Notes

## Move /boot to USB stick 

Motivation: [Evil Maid](https://lwn.net/Articles/359145/), a compromised bootloader 

Many people move /boot to USB stick and also write the bootloader to the MBR of that stick. I prefer to leave grub on the disk and only have /boot on stick, so I can disable booting from USB since that would allow for a quick and easy [Cold Boot Attack](https://en.wikipedia.org/wiki/Cold_boot_attack) and maybe even other crazy stuff like flashing chips with a nice persistent malware.

There is no reason to mount /boot again later, so I remove that entry from /etc/fstab (alternatively, set the "nooauto" option). For upgrades that affect /boot, you can always mount that part selectively.

I use a USB stick only for booting, and unplug the stick when the system is running.

**TODO**: Be aware that grub displays the UUID/label of the boot partition in case it cannot be found. Any reasonable attacker would simply create a matching stick, and voila, you are again vulnerable to (at least) the Cold Boot Attack.

## Verify MBR
 
Since I decided to use the MBR on the internal hard disk (plus backup on the boot stick), I verify hashes of the MBR later on in the boot phase.
   
See https://github.com/moba/hardened-boot/boot_integrity_checks

## Verify /boot and S.M.A.R.T. status

A script to verify hashes of /boot and monitor changes in S.M.A.R.T. attributes can be found at https://github.com/ioerror/smartmonster

## Keyfile for disk to USB stick

For two-factor authentication (a passphrase you know, and the physical token you have) what people usually do is have a keyfile that unlocks the hard disk on a USB stick. If you put the keyfile into a LUKS protected partition of your stick, you will have to unlock that with a passphrase first, then that keyfile can be used to unlock the disk. I use a separate small partition only for this purpose, so I can mount it read-only and directly unmount it again afterwards. Some people "hide" the keyfile between MBR and the first partition.

You can also use GnuPG to encrypt the keyfile. Potential benefit of that might be that you are using GnuPG in combination with a smartcard reader with external, more trustworthy keypad. Also, a smartcard cannot easily be tampered with without your knowledge, and smartcards are usually more robust than USB sticks (waterproof etc). For that route, see `README.gnupg` in `/usr/share/doc/cryptsetup/` (or `README.opensc.gz/openct.gz`).

    dd if=/dev/random of=/stick/keyfile bs=1 count=256
    cryptsetup luksAddKey /dev/sda1 keyfile
    
Since I want to use a keyfile for the root file system, I had to use a keyscript that mounts the stick first.

http://wejn.org/how-to-make-passwordless-cryptsetup.html shows the evolution of a generic keyscript for that purpose. It served as a blueprint for my stripped down version: It only luksmounts the specified USB device and the ext2 driver. You will probably prefer the original, since it is more flexible.

### /etc/crypttab

    sda1_crypt  UUID=[DISK-PARTITION-UUID] keyfile luks,discard,keyscript=/usr/local/sbin/crypto-usb-keyfile.sh

In case you decide to use my script: Edit the DEV variable to match your UUID!

Finally, run

    echo -e "ext2\nutf8" >> /etc/initramfs-tools/modules
    update-initramfs -u -k all

(with /boot mounted)

Try booting with your new key. 
If it fails for some reason, you can still manually decrypt the partition with your passphrase:

    cryptsetup luksOpen /dev/sda5 sda5_crypt
    # if you use LVM:
    vgchange -ay

Then press ^D to continue booting.

If everything works, you can remove the fallback passphrase from the hard disk:
  
    cryptsetup luksRemoveKey /dev/sda1
        
Or, keep it around for emergency purposes (but then make sure it is looong).

## Move LUKS header to USB stick

I figured if I have the stick anyway, why not move the whole LUKS header of the disk to that stick also. Turns out that crypttab does not support the option of an external header, not even with a custom keyscript.

## TODO

 * Investigate Secure Boot with TPM (see also [Anti Evil Maid](http://theinvisiblethings.blogspot.de/2011/09/anti-evil-maid.html)
 * Script to force me to unplug the stick after booting
