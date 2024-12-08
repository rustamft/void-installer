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
mkfs.vfat /dev/${disk}1
mkfs.ext2 /dev/${disk}2
mkfs.f2fs /dev/mapper/cryptroot
mkdir -p /mnt/target/boot/efi
mount /dev/mapper/cryptroot /mnt/target
mount /dev/${disk}2 /mnt/target/boot
mount /dev/${disk}1 /mnt/target/boot/efi
echo "Disk has been partitioned and mounted:"
echo "$(lsblk)"
