#!/bin/bash

echo "$(lsblk)"
while [ -z $disk ] || [ ! -e /dev/$disk ]; do
  read -p "Enter a valid disk name: " disk
done
# Empty lines in EOF section is default values
fdisk /dev/$disk << EOF
g # create a new GTP partition table
n # new partition
p # primary partition
1 # partition number 1

+500M # 500 MB EFI parttion
n # new partition
p # primary partition
2 # partion number 2

+500M # 500 MB boot parttion
n # new partition
p # primary partition
3 # partion number 3


p # print the in-memory partition table
w # write the partition table
q # and we're done
EOF
mkfs.vfat /dev/${disk}1
mkfs.ext2 /dev/${disk}2
cryptsetup luksOpen /dev/${disk}3
cryptsetup luksFormat /dev/mapper/cryptroot
void-installer
mount /dev/mapper/cryptroot /mnt
mount /dev/sda2 /mnt/boot
mount /dev/sda1 /mnt/boot/efi
xchroot /mnt
uuid=$(blkid -o value -s UUID /dev/mapper/cryptroot)
appendix="rd.auto=1 rd.luks.name=${uuid}=cryptroot rd.luks.allow-discards"
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& ${appendix}/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
xbps-reconfigure -fa
exit
umount -R /mnt
echo "Void Linux installed!"
