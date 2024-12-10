#!/bin/bash

echo "$(lsblk)"
while [ -z $disk ] || [ ! -e /dev/$disk ]; do
  read -p "Enter a valid disk name (e.g. sda): " disk
done
while [ -z $password ]; do
  read -p "Enter a password for the ${disk}3 partition encryption: " password
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


w
q
EOF
(echo $password; cat) | cryptsetup luksFormat /dev/${disk}3 -
(echo $password; cat) | cryptsetup luksOpen /dev/${disk}3 cryptroot -
echo "Disk has been partitioned:"
echo "$(lsblk)"
