#!/bin/bash

#
# Program: Chroot (change root system directory) <my-chrooting.sh>
#
# Author: Alexey Oknov <pitrider at mail dot ru>
# 
# Current Version: 1.0.0
#
# License:
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

CHROOT_DIR="/mnt/mychroot"
ROOT_DEV="/dev/sda1"

function usage(){
	printf "\nScript for chrooting\n"
	printf "\n\t%s -s <destination for chroot> -d <mount point>\n\n" $(basename "$0")
	printf "Usage:\n\t chroot /dev/sda1 to mount point /mnt/chrootdir\n\n\t %s -s /dev/sda1 -d /mnt/chrootdir \n\n" $(basename "$0")
}

if [ -z "$1" ]; then
	usage
	exit 1
fi

while getopts ":d:s:" option
do
    case "${option}" in
        d)
            CHROOT_DIR=${OPTARG}
            ;;
        s)
            ROOT_DEV=${OPTARG}
            ;;

        :)
            echo
            echo "Error: -${OPTARG} requires an argument."
            usage
            ;;
        *)
            usage
            ;;
    esac
done

if [ -b ${ROOT_DEV} ]; then
	mkdir "${CHROOT_DIR}"
	if [ ! -d "${CHROOT_DIR}" ]; then
		usage
	fi
	mount ${ROOT_DEV} "${CHROOT_DIR}"
	cp /etc/resolv.conf ${CHROOT_DIR}/etc/ 
	cd "${CHROOT_DIR}"
	mount --rbind /dev ${CHROOT_DIR}/dev
	mount --make-rslave ${CHROOT_DIR}/dev
	mount -t proc /proc ${CHROOT_DIR}/proc
	mount --rbind /sys ${CHROOT_DIR}/sys
	mount --make-rslave ${CHROOT_DIR}/sys
	mount --rbind /tmp ${CHROOT_DIR}/tmp
	chroot "${CHROOT_DIR}" /bin/bash
fi


