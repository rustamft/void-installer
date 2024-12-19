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
      desktop_environment="KDE" ;;
    *)
      desktop_environment="" ;;
  esac
done
mount /dev/mapper/cryptroot /mnt
mount /dev/${disk}2 /mnt/boot
mount /dev/${disk}1 /mnt/boot/efi
xchroot /mnt /bin/bash << EOF
# Enable services if any DE is chosen
case $desktop_environment in
  "GNOME"|"KDE)
    while [ -z \$username ] || ! id \$username >/dev/null 2>&1; do
      read -p "Enter your user name: " username
    done
    xbps-install -Sy dbus NetworkManager bluez tlp pipewire elogind mesa-dri wget
    # Enable general services
    rm /etc/runit/runsvdir/default/dhcpd
    ln -s /etc/sv/dbus /etc/runit/runsvdir/default/
    ln -s /etc/sv/NetworkManager /etc/runit/runsvdir/default/
    ln -s /etc/sv/bluetoothd /etc/runit/runsvdir/default/
    ln -s /etc/sv/tlp /etc/runit/runsvdir/default/
    # Enable PipeWire
    mkdir -p /etc/pipewire/pipewire.conf.d
    ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
    mkdir -p /home/\${username}/.config/autostart
    ln -s /user/share/applications/pipewire.desktop /home/\${username}/.config/autostart
    # Enable backlight level persisting
    mkdir /etc/sv/backlight
    wget https://raw.githubusercontent.com/madand/runit-services/refs/heads/master/backlight/finish -O /etc/sv/backlight/finish
    wget https://raw.githubusercontent.com/madand/runit-services/refs/heads/master/backlight/run -O /etc/sv/backlight/run
    ln -s /etc/sv/backlight /etc/runit/runsvdir/default/
    ;;
  *)
    ;;
esac
# Install the chosen DE
case $desktop_environment in
  "GNOME")
    xbps-install -Sy gdm gnome-core xdg-desktop-portal-gnome xdg-user-dirs nautilus file-roller alacritty flatpak
    ln -s /etc/sv/gdm /etc/runit/runsvdir/default/
    ;;
  "KDE")
    xbps-install -Sy sddm plasma-desktop xorg-minimal xdg-desktop-portal-kde xdg-user-dirs pcmanfm-qt ark alacritty flatpak
    ln -s /etc/sv/sddm /etc/runit/runsvdir/default/
    ;;
  *)
    ;;
esac
# Configure ZRAM
xbps-install -Sy zramen
echo "zramen -a zstd -n 6 -s 50 -p 100 make" >> /etc/rc.local
# Configure GRUB
xbps-install -Sy cryptsetup
uuid=$(blkid -o value -s UUID /dev/mapper/cryptroot)
appendix="rd.auto=1 rd.luks.name=\${uuid}=cryptroot rd.luks.allow-discards"
sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*/& \${appendix}/" /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --boot-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
xbps-reconfigure -fa
exit
EOF
umount -R /mnt
echo "Void Linux startup configured!"
