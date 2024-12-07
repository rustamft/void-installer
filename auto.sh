echo "$(lsblk)"
while [ -z $disk ] -o [ ! -e /dev/$disk ]; do
  read -p "Enter a valid disk name: " disk
done
fdisk /dev/$disk << EOF
o # clear the in memory partition table
n # new partition
p # primary partition
1 # partition number 1
# default - start at beginning of disk 
+500M # 500 MB EFI parttion
n # new partition
p # primary partition
2 # partion number 2
# default, start immediately after preceding partition
+500M # 500 MB boot parttion
n # new partition
p # primary partition
3 # partion number 3
# default, start immediately after preceding partition
# default, extend partition to end of disk
p # print the in-memory partition table
w # write the partition table
q # and we're done
EOF
mkfs.vfat /dev/$disk1
mkfs.ext2 /dev/$disk2
cryptsetup luksOpen /dev/$disk3
cryptsetup luksFormat /dev/mapper/cryptroot
void-installer
mount /dev/mapper/cryptroot /mnt
mount /dev/sda2 /mnt/boot
mount /dev/sda1 /mnt/boot/efi
xchroot /mnt
uuid=$(blkid -o value -s UUID /dev/mapper/cryptroot)
appendix="rd.auto=1 rd.luks.name=$uuid=cryptroot rd.luks.allow-discards"
sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& $appendix/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
xbps-reconfigure -fa
exit
umount -R /mnt
echo "Void Linux installed!"
