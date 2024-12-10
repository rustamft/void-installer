#!/bin/bash

echo "$(lsblk)"
while [ -z $disk ] || [ ! -e /dev/$disk ]; do
  read -p "Enter a valid disk name (e.g. sda): " disk
done
while [ -z $password ] || [ $password != $password_confirmation ]; do
  read -s -p "Enter a password for the ${disk}3 partition encryption: " password
  printf "\n"
  read -s -p "Please repeat to confirm: " password_confirmation
  printf "\n"
done
fdisk /dev/$disk << EOF
g
n
1
  read -p "Enter a valid disk name (e.g. sda): " disk
done
while [ -z $password ]; do
  read -s -p "Enter a password for the ${disk}3 partition encryption: " password
  read -s -p "Please repeat to confirm: " password_confirmation
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

+500M
n
2

+500M
n
3


w
q
EOF
echo -n $password | cryptsetup luksFormat /dev/${disk}3 -
echo -n $password | cryptsetup luksOpen /dev/${disk}3 cryptroot -
printf "Disk has been partitioned:\n"
echo "$(lsblk)"
