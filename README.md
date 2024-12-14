This is used to automate installation of Void Linux.

The chosen disk is divided in 3 partitions:
1) efi - 500 Mb - unencrypted
2) boot - 1000 Mb - unencrypted
3) root - the rest of the disk - encrypted using LUKS without LVM

Commands order:
1) sudo -i /bin/bash
2) xbps-install -S wget
3) wget https://raw.githubusercontent.com/rustamft/void-installer/refs/heads/main/1-partition.sh -O /tmp/1.sh
4) chmod +x /tmp/1.sh
5) /tmp/1.sh
6) void-installer # Skip the partition section and don't reboot at the end, just exit the void-installer
7) wget https://raw.githubusercontent.com/rustamft/void-installer/refs/heads/main/2-configure.sh -O /tmp/2.sh
8) chmod +x /tmp/2.sh
9) /tmp/2.sh
10) reboot now
