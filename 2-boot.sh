#!/bin/bash

echo "##############################################"
echo "###                                        ###"
echo "###   Wellcome to the Boot Setup script!   ###"
echo "###                                        ###"
echo "##############################################"
echo "Your current block devices:"
lsblk -I 8,253,254,259
while [[ -z $disk ]] || [[ ! -e /dev/$disk ]]; do
  read -p "Enter previously partitioned disk name (e.g. sda or nvme0n1): " disk
done
if [[ $disk == *"nvme"* ]]; then
  disk_partition_1="${disk}p1"
  disk_partition_2="${disk}p2"
  disk_partition_3="${disk}p3"
else
  disk_partition_1="${disk}1"
  disk_partition_2="${disk}2"
  disk_partition_3="${disk}3"
fi
if [[ ! -e /dev/$disk_partition_1 ]] || [[ ! -e /dev/$disk_partition_2 ]] || [[ ! -e /dev/$disk_partition_3 ]]; then
  echo "${disk} is not partitioned correctly"
  exit
fi
if [[ ! -e /dev/mapper/cryptroot ]]; then
  cryptsetup luksOpen /dev/$disk_partition_3 cryptroot
fi
mount /dev/mapper/cryptroot /mnt
mount /dev/$disk_partition_2 /mnt/boot
mount /dev/$disk_partition_1 /mnt/boot/efi
while [[ -z $is_de_script_required ]]; do
  read -p "Would you like to download a desktop environment installation script to your user directory? [Y/n] " is_de_script_required
  case $is_de_script_required in
    ""|"Y"|"y")
      is_de_script_required=true
      while [[ -z $username ]] || [[ ! -d /mnt/home/$username ]]; do
        read -p "Enter your user name: " username
      done
      ;;
    "N"|"n")
      is_de_script_required=false ;;
    *)
      printf "This is not an option\n"
      unset is_de_script_required
      ;;
  esac
done
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
echo "##########################################"
echo "###                                    ###"
echo "###    Void Linux is ready to boot!    ###"
echo "###                                    ###"
echo "##########################################"
