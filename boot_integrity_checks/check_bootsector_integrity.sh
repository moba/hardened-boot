#!/bin/bash

## 
## check_bootsector_integrity.sh
##
## compares hash of first 512 bytes on disk (MBR)
## to stored hash
##
## 2013-10-09 moritz bartl
## public domain/cc0/wtfpl
##

DIR=/root/boot_integrity
HASHFILE=$DIR/bootsector.sha1
IMAGE=$DIR/bootsector.img
LOCATION=/dev/sda

##################################################

if [[ $EUID -ne 0 ]]; then
 echo "$0 must be run as root to read MBR" 1>&2
 read 
 exit 1
fi

NEWHASH=`dd if=$LOCATION bs=512 count=1 2>/dev/null | sha1sum -b - | cut -d " " -f 1`

if [ -f $HASHFILE ]; then
 OLDHASH=`cat $HASHFILE`
 if [ "$NEWHASH" == "$OLDHASH" ]; then
  # echo hash of current bootsector matches stored hash
  exit 0
 fi
else
 OLDHASH="(not found)"
fi

echo -e "\033[1m" # bold 
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo BOOT SECTOR MODIFIED
echo old: $OLDHASH 
echo new: $NEWHASH
echo !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
echo -e "\033[0m" # unbold
read -p "Update hash and known image (y/N): " update

shopt -s nocasematch

if [[ $update == "y" ]]; then
 echo $NEWHASH > $HASHFILE
 dd if=$LOCATION bs=512 count=1 of=$IMAGE &>/dev/null
 echo Last known hash and image updated.
fi
