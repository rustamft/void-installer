#!/bin/bash

echo "$(lsblk)"
while [ -z $disk ] || [ ! -e /dev/$disk ]; do
  read -p "Enter a valid disk name (e.g. sda): " disk
done
while [ -z $is_de_script_required ]; do
  printf "Would you like to download a desktop environment installation script to your user directory? [Y/n]\n"
  read input
  case $input in
    ""|"Y"|"y")
      is_de_script_required=true
      while [ -z $username ] || [ ! -d /mnt/home/$username ]; do
        read -p "Enter your user name: " username
      done
      ;;
    "N"|"n")
      is_de_script_required=false ;;
    *)
      printf "This is not an option\n" ;;
  esac
done
mount /dev/mapper/cryptroot /mnt
mount /dev/${disk}2 /mnt/boot
mount /dev/${disk}1 /mnt/boot/efi
xchroot /mnt /bin/bash << EOF
  xbps-install -yRs void-repo-nonfree
  xbps-install -Sy cryptsetup zramen
  uuid=$(blkid -o value -s UUID /dev/mapper/cryptroot)
  appendix="rd.auto=1 rd.luks.name=\${uuid}=cryptroot rd.luks.allow-discards"
  sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*/& \${appendix}/" /etc/default/grub
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot
  xbps-reconfigure -fa
  echo "zramen -a zstd -n 6 -s 50 -p 100 make" >> /etc/rc.local
  exit
EOF
if $is_de_script_required; then
  wget https://raw.githubusercontent.com/rustamft/void-installer/refs/heads/main/3-de.sh -O /mnt/home/${username}/3-de.sh
fi
umount -R /mnt
cryptsetup luksClose /dev/mapper/cryptroot
echo "Void Linux is ready to boot!"
