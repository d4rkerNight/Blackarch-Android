#!/bin/sh
################################################################
#
# Android blackarch: blackarch_arm.sh
#
# Prerequisites:
#
# 1] Format external sdcard (in my case ext3)
# 2] Device rooted
# 3] Busybox
# 4] Blackarch arm (line 40): archlinuxarm.org/platforms
# 5] Check mirror: blackarch.org/download.html#mirrors
# 6] Run: busybox sh  blackarch_arm.sh
#
# I haven't checked all the terminal tools but the ones
# that I need work
#
# eg: msfconsole, nmap, sqlmap, ...
#
# Tested on sgs3 SHV-E210K
#
#
# by tesla
###############################################################

# check root priv
if [ "$(busybox id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
clear

# change as required
EXT_SDCARD="/storage/extSdCard"
INT_BLACK="/storage/sdcard0/blackarch/"
MOUNT="/dev/block/mmcblk1p1"
MNT="mount.sh"
UMNT="umount.sh"
INT_UMNT="umount.sh"
ARM="ArchLinuxARM-odroid-xu-latest.tar.gz"
MIRROR="http://www.mirrorservice.org/sites/blackarch.org/blackarch"

if [[ ! -d "${INT_BLACK}" ]]; then
  mkdir ${INT_BLACK}
fi

mountpoint -q ${EXT_SDCARD}                                                
if [[ ! $? -eq 0 ]]; then
  mount -o rw -t ext3 ${MOUNT} ${EXT_SDCARD}
fi

if [[ ! -f "${EXT_SDCARD}/.bash_history" ]]; then
  if [[ ! -f ${INT_BLACK}${ARM} ]]; then                           
    wget http://archlinuxarm.org/os/${ARM} -P ${INT_BLACK}         
  fi
  tar xzf ${INT_BLACK}ArchLinuxARM*.tar.gz -C ${EXT_SDCARD}
fi

mount -o bind /dev/ ${EXT_SDCARD}/dev/
mount -o bind /dev/pts/ ${EXT_SDCARD}/dev/pts/

echo "nameserver 8.8.8.8" > ${EXT_SDCARD}/etc/resolv.conf # 'nameserver' change as required

profile=$(tail -n 1 ${EXT_SDCARD}/etc/profile | awk '{print $1}')

if [[ "${profile}" != "export" ]]; then
  echo "export TERM=xterm" >> ${EXT_SDCARD}/etc/profile
  echo "export HOME=/root" >> ${EXT_SDCARD}/etc/profile
fi

pacman=$(tail -n 1 ${EXT_SDCARD}/etc/pacman.conf | awk '{print $1}')

if [[ "${pacman}" != "Server" ]]; then
  echo "[blackarch]" >> ${EXT_SDCARD}/etc/pacman.conf
  echo "Server = ${MIRROR}/\$repo/os/\$arch" >> ${EXT_SDCARD}/etc/pacman.conf
fi

if [[ ! -f ${INT_BLACK}${INT_UMNT} ]]; then
  echo "#!/bin/bash" >> ${INT_BLACK}${INT_UMNT}
  echo "umount ${EXT_SDCARD}/dev/pts" >> ${INT_BLACK}${INT_UMNT}
  echo "umount ${EXT_SDCARD}/dev" >> ${INT_BLACK}${INT_UMNT}
  echo "umount ${EXT_SDCARD}" >> ${INT_BLACK}${INT_UMNT}
fi

if [[ ! -f ${EXT_SDCARD}/home/${MNT} ]]; then
  echo "#!/bin/bash" > ${EXT_SDCARD}/home/${MNT}
  echo "mountpoint -q /proc" >> ${EXT_SDCARD}/home/${MNT}
  echo "if [[ ! $? -eq 0 ]]; then" >> ${EXT_SDCARD}/home/${MNT}
  echo "  mount -t proc proc /proc/" >> ${EXT_SDCARD}/home/${MNT}
  echo "  mount -t sysfs sysfs /sys/" >> ${EXT_SDCARD}/home/${MNT}
  echo "fi" >> ${EXT_SDCARD}/home/${MNT}
  echo "source /etc/profile" >> ${EXT_SDCARD}/home/${MNT}
fi

if [[ ! -f ${EXT_SDCARD}/home/${UMNT} ]]; then
  echo "#!/bin/bash" >> ${EXT_SDCARD}/home/${UMNT}
  echo "umount /sys/" >> ${EXT_SDCARD}/home/${UMNT}
  echo "umount /proc/" >> ${EXT_SDCARD}/home/${UMNT}
fi

if [[ ! -f ${EXT_SDCARD}/.bashrc ]]; then
  echo "sh /home/mount.sh" >> ${EXT_SDCARD}/.bashrc
  echo "alias ls=\"ls --color -hal \"" >> ${EXT_SDCARD}/.bashrc
  echo "alias grep=\"grep --color \"" >> ${EXT_SDCARD}/.bashrc
  # list tools
  echo "alias blacktools=\"pacman -Sgg | grep blackarch | cut -d ' ' -f2 | sort -u\"" >> ${EXT_SDCARD}/.bashrc
  # list category
  echo "alias blackcats=\"pacman -Sg | grep blackarch\"" >> ${EXT_SDCARD}/.bashrc
  echo "alias quit=\"sh /home/umount.sh && exit\"" >> ${EXT_SDCARD}/.bashrc
fi

echo ""
echo "Umount && quit:"
echo "run: quit"
echo ""
echo "pacman -Syyu"
echo "pacman -S gcc"
echo "pacman -Sg | grep blackarch \"alias = blackcats\""
echo "pacman -Sgg | grep blackarch | cut -d ' ' -f2 | sort -u \"alias = blacktools\""

alias umblack="sh ${INT_BLACK}${INT_UMNT}"

chroot ${EXT_SDCARD} bash
umblack
echo ""
echo "Umount blackarch Done!"
echo ""
