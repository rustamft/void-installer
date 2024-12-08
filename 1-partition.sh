#!/bin/bash

echo "$(lsblk)"
while [ -z $disk ] || [ ! -e /dev/$disk ]; do
  read -p "Enter a valid disk name: " disk
done
fdisk /dev/$disk << EOF
g
n
1

+500M
n
2

+500M
n
3


p
w
q
EOF
cryptsetup luksFormat /dev/${disk}3
cryptsetup luksOpen /dev/${disk}3 cryptroot
echo "Disk has been partitioned:"
echo "$(lsblk)"
