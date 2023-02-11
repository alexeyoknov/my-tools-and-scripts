#!/bin/bash

#
# Program: Install httpd and munin in CentOS <centos-httpd-munin-install.sh>
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
    printf "\nThis program installs httpd and munin in CentOS\n"
    printf "\nUsage:\n\t%s [-h]" "$(basename "$0")"
    printf "\n\t-h\tshow this help\n"
    printf "\nExample:\n\t%s\n\n" "$(basename "$0")"
    exit 1
}

while getopts ":h" option
do
    case "${option}" in
        h)
            usage
            ;;
    esac
done

os_id() {
    OS_ID=0
    if [ -f "/etc/os-release" ]; then
        OS_ID=$(grep "^ID=" /etc/os-release | cut -d= -f2 | sed 's/"//g')
    fi
    echo ${OS_ID}
}

osid=$(os_id)

if [ "${osid}" != "centos" ]; then
    echo "Your system not CentOS"
    exit
fi

if [ $(id -g) -gt 0 ]; then 
    echo
    echo "Run this script as root or via sudo"
    echo    
    exit 1
fi

#install httpd
yum -y install httpd
systemctl enable httpd
systemctl start httpd

#ports enabling
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=3306/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent
    firewall-cmd --reload

#install munin
yum -y install munin munin-node

#configure munin
htpasswd -c /etc/munin/munin-htpasswd admin

