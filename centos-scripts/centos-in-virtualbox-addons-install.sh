#!/bin/bash

#
# Program: Install VirtualBox additions <centos-in-virtualbox-addonst-install.sh>
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


usage() {
    printf "\nThis program installs VB additions and some other packages in CentOS\n"
    printf "\nUsage:\n\t%s [-n -h]" "$(basename "$0")"
    printf "\n\n\t-n\tnot install other packages like wget,htop,mc\n"
    printf "\n\t-h\tshow this help\n"
    printf "\nExample:\n\t%s -n\n\n" "$(basename "$0")"
    exit 1
}

os_id() {
    OS_ID=0
    # centos 7
    if [ -f "/etc/os-release" ]; then
        OS_ID=$(grep "^ID=" /etc/os-release | cut -d= -f2 | sed 's/"//g')
    else
        # centos 6.9
        if [ -f "/etc/centos-release" ]; then
            OS_ID="centos"
        fi
    fi
    echo ${OS_ID}
}

osid=$(os_id)

NOT_INSTALL_COMMON=0

if [ "${osid}" != "centos" ]; then
    echo "Your system not CentOS"
    exit
fi

while getopts ":ch" option
do
    case "${option}" in
        c)
            NOT_INSTALL_COMMON=1
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

if [ $(id -g) -gt 0 ]; then 
    echo
    echo "Run this script as root or via sudo"
    echo    
    exit 1
fi

#update packages
yum -y update

#packages for Addons
yum -y install bzip2 kernel-devel gcc make perl kernel-headers

#common
if [ ${NOT_INSTALL_COMMON} -eq 0 ]; then
    yum -y install epel-release
    yum -y install wget mc htop net-tools
fi

if [ ! -d /media/mycd ]; then
    mkdir /media/mycd
fi

mount -o loop /dev/sr0 /media/mycd

if [ -f /media/mycd/VBoxLinuxAdditions.run ]; then
    /media/mycd/VBoxLinuxAdditions.run
fi

umount /media/mycd
