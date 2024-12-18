#!/bin/bash

echo "$(lsblk)"
while [ -z $disk ] || [ ! -e /dev/$disk ]; do
  read -p "Enter a valid disk name (e.g. sda): " disk
done
while [ -z $desktop_environment ]; do
  printf "Choose desktop environment to install:\n  1) none\n  2) GNOME\n  3) KDE\n"
  read desktop_environment
  case $desktop_environment in
    "1")
      desktop_environment="none" ;;
    "2")
      desktop_environment="GNOME" ;;
    "3")
      desktop_environment="KDE"; echo "KDE isn't yet supported"; exit 1 ;;
    *)
      desktop_environment="" ;;
  esac
done
mount /dev/mapper/cryptroot /mnt
mount /dev/${disk}2 /mnt/boot
mount /dev/${disk}1 /mnt/boot/efi
xchroot /mnt /bin/bash << EOF
xbps-install -Sy cryptsetup
uuid=$(blkid -o value -s UUID /dev/mapper/cryptroot)
appendix="rd.auto=1 rd.luks.name=\${uuid}=cryptroot rd.luks.allow-discards"
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*/& \${appendix}/" /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
xbps-reconfigure -fa
if [ $desktop_environment != "none" ]; then
  xbps-install -S dbus NetworkManager bluez tlp pipewire elogind mesa-dri
  rm /var/services/dhcpd
  ln -s /etc/sv/dbus /var/service
  ln -s /etc/sv/NetworkManager /var/service
  ln -s /etc/sv/bluetoothd /var/service
  ln -s /etc/sv/tlp /var/service
  mkdir -p /etc/pipewire/pipewire.conf.d
  ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
  mkdir -p ~/.config/autostart
  ln -s /user/share/applications/pipewire.desktop ~/.config/autostart
fi
case $desktop_environment in
  "GNOME")
    xbps-install -S gdm gnome-core xdg-desktop-portal-gnome xdg-user-dirs nautilus file-roller alacritty flatpak
    ln -s /etc/sv/gdm /var/service
    ;;
  "KDE")
    xbps-install -S sddm plasma-desktop xorg-minimal xdg-user-dirs pcmanfm-qt alacritty flatpak
    ln -s /etc/sv/sddm /var/service
    ;;
  *)
    ;;
esac
exit
EOF
umount -R /mnt
echo "Void Linux startup configured!"
