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
# 6] Run: busybox sh blackarch_arm.sh
#
# I haven't checked all the terminal tools but the ones
# that I need work
#
# eg: metasploit, nmap, sqlmap, ...
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

EXT_SDCARD="/storage/extSdCard" # change as required
INT_BLACK="/storage/sdcard0/armblack/" # change has required
IMG="arm_blackarch.img"
LOOP="/dev/loop1337"
MOUNT="mount.sh"
UMOUNT="umount.sh"
INT_UMOUNT="umount.sh"
ARM="ArchLinuxARM-odroid-xu-latest.tar.gz" # change as required
MIRROR="http://www.mirrorservice.org/sites/blackarch.org/blackarch" # change as required

if [[ ! -d "${INT_BLACK}" ]]; then
  mkdir ${INT_BLACK}
fi

if [[ ! -f "${INT_BLACK}${IMG}" ]]; then
  dd if=/dev/zero of=${INT_BLACK}${IMG} bs=7168 count=1048576 # 7G change as required
  mke2fs -F ${INT_BLACK}${IMG}
fi

if [[ ! -b "${LOOP}" ]]; then
  mknod ${LOOP} b 7 256
fi
losetup ${LOOP} ${INT_BLACK}${IMG}
busybox mount -t ext3 ${LOOP} ${EXT_SDCARD}

if [[ ! -f "${INT_BLACK}${ARM}" ]]; then
  wget http://archlinuxarm.org/os/${ARM} -P ${INT_BLACK}
  tar xzf ${INT_BLACK}ArchLinuxARM*.tar.gz -C ${EXT_SDCARD}
fi

busybox mount -o bind /dev/ ${EXT_SDCARD}/dev/
busybox mount -o bind /dev/pts/ ${EXT_SDCARD}/dev/pts/

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

if [[ ! -f ${INT_BLACK}${INT_UMOUNT} ]]; then
  echo "#!/bin/bash" >> ${INT_BLACK}${INT_UMOUNT}
  echo "umount ${EXT_SDCARD}/dev/pts" >> ${INT_BLACK}${INT_UMOUNT}
  echo "umount ${EXT_SDCARD}/dev" >> ${INT_BLACK}${INT_UMOUNT}
  echo "umount ${EXT_SDCARD}" >> ${INT_BLACK}${INT_UMOUNT}
fi

if [[ ! -f ${EXT_SDCARD}/home/${MOUNT} ]]; then
  echo "#!/bin/bash" >> ${EXT_SDCARD}/home/${MOUNT}
  echo "mount -t proc proc /proc/" >> ${EXT_SDCARD}/home/${MOUNT}
  echo "mount -t sysfs sysfs /sys/" >> ${EXT_SDCARD}/home/${MOUNT}
  echo "source /etc/profile" >> ${EXT_SDCARD}/home/${MOUNT}
fi

if [[ ! -f ${EXT_SDCARD}/home/${UMOUNT} ]]; then
  echo "#!/bin/bash" >> ${EXT_SDCARD}/home/${UMOUNT}
  echo "umount /sys/" >> ${EXT_SDCARD}/home/${UMOUNT}
  echo "umount /proc/" >> ${EXT_SDCARD}/home/${UMOUNT}
fi

if [[ ! -f ${EXT_SDCARD}/.bashrc ]]; then
  echo "sh /home/mount.sh" >> ${EXT_SDCARD}/.bashrc
  # list tools
  echo "alias blacktools=\"pacman -Sgg | grep blackarch | cut -d ' ' 'f2 | sort -u\"" >> ${EXT_SDCARD}/.bashrc
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

alias umblack="sh ${INT_BLACK}${INT_UMOUNT}"

chroot ${EXT_SDCARD} bash # "bash" change as required
umblack
echo ""
echo "Umount blackarch Done!"
echo ""
