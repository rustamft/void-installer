#!/bin/bash

if [ $EUID -ne 0 ]; then
  echo 'Root priveleges required to run the script'
  exit
fi
while [ $desktop_environment != "none" ] && ( [ -z $username ] || [ -z $(grep "^${username}:" /mnt/etc/passwd) ] ); do
  read -p "Enter your user name: " username
done
while [ -z $desktop_environment ]; do
  printf "Choose desktop environment to install:\n  1) GNOME\n  2) KDE\n"
  read desktop_environment
  case $desktop_environment in
    "1")
      desktop_environment="GNOME" ;;
    "2")
      desktop_environment="KDE" ;;
    *)
      desktop_environment="" ;;
  esac
done
xbps-install -Sy dbus NetworkManager bluez tlp pipewire elogind mesa-dri wget flatpak
ln -s /etc/sv/dbus /var/service
rm /var/service/dhcpcd
ln -s /etc/sv/NetworkManager /var/service
ln -s /etc/sv/bluetoothd /var/service
ln -s /etc/sv/tlp /var/service
mkdir -p /etc/pipewire/pipewire.conf.d
ln -s /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d/
mkdir -p /home/${username}/.config/autostart
ln -s /user/share/applications/pipewire.desktop /home/${username}/.config/autostart
mkdir /etc/sv/backlight
wget https://raw.githubusercontent.com/rustamft/void-installer/refs/heads/main/backlight/finish -O /etc/sv/backlight/finish
wget https://raw.githubusercontent.com/rustamft/void-installer/refs/heads/main/backlight/run -O /etc/sv/backlight/run
ln -s /etc/sv/backlight /var/service
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
case $desktop_environment in
  "GNOME")
    xbps-install -Sy gdm gnome-core xdg-desktop-portal-gnome xdg-user-dirs nautilus file-roller alacritty
    ln -s /etc/sv/gdm /var/service
    ;;
  "KDE")
    xbps-install -Sy sddm kde-kcm plasma-desktop xorg-minimal xdg-desktop-portal-kde xdg-user-dirs pcmanfm-qt ark alacritty
    ln -s /etc/sv/sddm /var/service
    ;;
  *)
    printf '\nInstallation failed'
    exit
    ;;
esac
