#!/usr/bin/env bash

#
# Program: add gentoo overlay and mask its all packages <layman_add.sh>
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

if [ $(id -g) -gt 0 ]; then 
    echo
    echo "Run this script as root or via sudo"
    echo    
    exit 1
fi

if [ -z "$1" ]; then
    exit 0
fi

NEW_OVERLAY="$1"

layman -a "${NEW_OVERLAY}"

if [ ! -d "/var/lib/layman/${NEW_OVERLAY}" ]; then
    echo "Error while adding overlay"
    exit 0
else
    if [ ! -d "/var/lib/layman/${NEW_OVERLAY}/metadata" ]; then
        mkdir "/var/lib/layman/${NEW_OVERLAY}/metadata"
    fi
    echo "masters = gentoo" > "/var/lib/layman/${NEW_OVERLAY}/metadata/layout.conf"

    if [ "${NEW_OVERLAY}" != "gentoo" ] && [ "${NEW_OVERLAY}" != "calculate" ]; then
        echo "*/*::${NEW_OVERLAY}" >> /etc/portage/package.mask/overlays
    fi
    eix-update
fi
