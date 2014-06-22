#!/bin/bash
########################################
#
# Android blackarch: blackarch_arm.sh
#
# Prerequisites:
#
# 1] Format external sdcard (ext2)
# 2] Device rooted
# 3] Busybox
# 4] Blackarch arm (line 38): archlinuxarm.org/platforms
# 5] Check mirror: blackarch.org/download.html#mirrors
# 6] Run: busybox sh blackarch_arm.sh
#
# I haven't checked all the tools but the ones that I need work
# eg: metasploit, nmap, ...
#
# Tested on sgs3 SHV-E210K
# 
#
# by tesla
########################################

# check root priv
if [ "$(busybox id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi
clear

EXT_SDCARD="/storage/extSdCard" # change has required
INT_BLACK="/storage/sdcard0/blackarch/" # change has required
IMG="arm_blackarch.img"
LOOP="/dev/loop1337"
MOUNT="mount.sh"
UMOUNT="umount.sh"
INT_UMOUNT="umount.sh"
ARM="ArchLinuxARM-odroid-xu-latest.tar.gz" # change has required
MIRROR="http://www.mirrorservice.org/sites/blackarch.org/blackarch" # change has required

if [[ ! -d "${INT_BLACK}" ]]; then
  mkdir ${INT_BLACK}
fi

if [[ ! -f "${INT_BLACK}${IMG}" ]]; then
  dd if=/dev/zero of=${INT_BLACK}${IMG} seek=10000000000 bs=1 count=1
  mke2fs -F ${INT_BLACK}${IMG}
fi

if [[ -e "mknod ${LOOP} b 7 256" ]]; then
  mknod ${LOOP} b 7 256
fi
losetup ${LOOP} ${INT_BLACK}${IMG}
busybox mount -t ext2 ${LOOP} ${EXT_SDCARD}

if [[ ! -f "${INT_BLACK}${ARM}" ]]; then
  wget http://archlinuxarm.org/os/${ARM} -P ${INT_BLACK}
  tar xzf ${INT_BLACK}ArchLinuxARM*.tar.gz -C ${EXT_SDCARD}
fi

busybox mount -o bind /dev/ ${EXT_SDCARD}/dev/
busybox mount -o bind /dev/pts/ ${EXT_SDCARD}/dev/pts/

echo "nameserver 8.8.8.8" > ${EXT_SDCARD}/etc/resolv.conf

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

echo ""
echo "Mount proc && sysfs:"
echo "sh /home/mount.sh"
echo ""
echo "Umount:"
echo "sh /home/umount.sh"
echo ""
echo "pacman -Syyu"
echo "pacman -S gcc"
echo "pacman -Sg | grep blackarch"
chroot ${EXT_SDCARD} sh
