#!/bin/bash

if [ $EUID -ne 0 ]; then
  echo 'Root priveleges required to run the script'
  exit
fi
echo "####################################################################"
echo "###                                                              ###"
echo "###   Wellcome to the Desktop Environment installation script!   ###"
echo "###                                                              ###"
echo "###            Note, the computer will be restarted,             ###"
echo "###             when the installation is complete!               ###"
echo "###                                                              ###"
echo "####################################################################"
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
while [ -z $is_flatpak_required ]; do
  read -p "Is Flatpak installation required? [Y/n] " is_flatpak_required
  case $is_flatpak_required in
    ""|"Y"|"y")
      is_flatpak_required=true ;;
    "N"|"n")
      is_flatpak_required=false ;;
    *)
      printf "This is not an option\n"
      unset is_flatpak_required
      ;;
  esac
done
xbps-install -Sy dbus NetworkManager bluez tlp pipewire elogind mesa-dri wget
ln -sf /etc/sv/dbus /var/service
rm /var/service/dhcpcd
ln -sf /etc/sv/NetworkManager /var/service
ln -sf /etc/sv/bluetoothd /var/service
ln -sf /etc/sv/tlp /var/service
mkdir -p /etc/pipewire/pipewire.conf.d
ln -sf /usr/share/examples/wireplumber/10-wireplumber.conf /etc/pipewire/pipewire.conf.d
ln -sf /usr/share/examples/wireplumber/20-pipewire-pulse.conf /etc/pipewire/pipewire.conf.d
ln -sf /usr/share/applications/pipewire.desktop /etc/xdg/autostart
chmod +x /usr/share/applications/pipewire.desktop
ln -sf /usr/share/applications/pipewire-pulse.desktop /etc/xdg/autostart
chmod +x /usr/share/applications/pipewire-pulse.desktop
mkdir /etc/sv/backlight
wget https://raw.githubusercontent.com/rustamft/void-installer/refs/heads/main/backlight/finish -O /etc/sv/backlight/finish
wget https://raw.githubusercontent.com/rustamft/void-installer/refs/heads/main/backlight/run -O /etc/sv/backlight/run
ln -sf /etc/sv/backlight /var/service
case $desktop_environment in
  "GNOME")
    xbps-install -Sy gdm gnome-core xdg-desktop-portal-gnome xdg-user-dirs nautilus file-roller alacritty
    ln -sf /etc/sv/gdm /var/service
    ;;
  "KDE")
    xbps-install -Sy xorg-minimal sddm sddm-kcm ntp plasma-desktop kwallet-pam plasma-pa kpipewire kscreen xdg-desktop-portal-kde xdg-user-dirs pcmanfm-qt gvfs ark unrar alacritty
    ln -sf /etc/sv/sddm /var/service
    ;;
  *)
    printf '\nInstallation failed'
    exit
    ;;
esac
if $is_flatpak_required; then
  xbps-install -Sy flatpak
  flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
fi
if [ -d /var/service/gdm ] || [ -d /var/service/sddm ]; then
  printf "\n${desktop_environment} installation is complete! Restarting...\n"
  reboot now
else
  printf "\n${desktop_environment} installation isn't complete, please check installed packages\n"
fi
