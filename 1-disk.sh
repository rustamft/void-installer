#!/bin/bash

echo "#################################################################"
echo "###                                                           ###"
echo "###          Wellcome to the Disk Partition script!           ###"
echo "###                                                           ###"
echo "###                         WARNING!                          ###"
echo "###   The script will destroy all data on a disk you choose   ###"
echo "###                                                           ###"
echo "#################################################################"
echo "Your current disks and partitions:"
lsblk -I 8,253,254,259
while [[ -z $disk ]] || [[ ! -e /dev/$disk ]]; do
  read -p "Enter a valid disk name (e.g. sda or nvme0n1): " disk
done
if [[ $disk == *"nvme"* ]]; then
  disk_partition_3="${disk}p3"
else
  disk_partition_3="${disk}3"
fi
while [[ -z $password ]] || [[ $password != $password_confirmation ]]; do
  read -s -p "Enter a password for the ${disk_partition_3} partition encryption: " password
  printf "\n"
  read -s -p "Please repeat to confirm: " password_confirmation
  printf "\n"
done
fdisk /dev/$disk << EOF
g
n
1

+500M
n
2

+1000M
n
3


w
q
EOF
echo -n $password | cryptsetup luksFormat /dev/$disk_partition_3 -
echo -n $password | cryptsetup luksOpen /dev/$disk_partition_3 cryptroot -
if [[ -e /dev/$disk_partition_3 ]] && [[ -e /dev/mapper/cryptroot ]]; then
  printf "\nDisk has been partitioned:\n"
  lsblk -I 8,253,254,259
else
  printf "\nSomething went wrong, disk has not been partitioned\n"
fi
