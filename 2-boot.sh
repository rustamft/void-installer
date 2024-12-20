#!/bin/bash

echo "$(lsblk)"
while [ -z $disk ] || [ ! -e /dev/$disk ]; do
  read -p "Enter a valid disk name (e.g. sda): " disk
done
mount /dev/mapper/cryptroot /mnt
mount /dev/${disk}2 /mnt/boot
mount /dev/${disk}1 /mnt/boot/efi
xchroot /mnt /bin/bash << EOF
  xbps-install -yRs void-repo-nonfree
  xbps-install -Sy cryptsetup
  uuid=$(blkid -o value -s UUID /dev/mapper/cryptroot)
  appendix="rd.auto=1 rd.luks.name=\${uuid}=cryptroot rd.luks.allow-discards"
  sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*/& \${appendix}/" /etc/default/grub
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot
  xbps-reconfigure -fa
  xbps-install -Sy zramen
  echo "zramen -a zstd -n 6 -s 50 -p 100 make" >> /etc/rc.local
  exit
EOF
umount -R /mnt
cryptsetup luksClose /dev/mapper/cryptroot
echo "Void Linux is ready to boot!"
