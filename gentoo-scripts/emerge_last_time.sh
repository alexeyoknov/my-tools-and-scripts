#!/bin/bash

#
# Program: Show elapsed time for current compiled portage <emerge_last_time.sh>
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

function _secondsToUser() {
    local TIME_IN_SECONDS="$1"
    
    h="$((TIME_IN_SECONDS/3600))"
    m="$(((TIME_IN_SECONDS-h*3600)/60))"
    s="$((TIME_IN_SECONDS-h*3600-m*60))" 
    echo "$h hours $m minutes $s seconds"
}


BUILD_START_TIME_IN_SECONDS=$(tail -n20 /var/log/emerge.log | grep ">>> emerge"|tail -n1|awk -F: '{print $1}')
BUILD_START_LAST_TIME_FORMATED=$(date -d@"${BUILD_START_TIME_IN_SECONDS}")
CURRENT_TIME=$(date '+%s')
ELAPSED_TIME="$((CURRENT_TIME - BUILD_START_TIME_IN_SECONDS))"

ut="emerge completed"

PORTAGE_NAME=$(tail -n20 /var/log/emerge.log | awk '(($2==">>>")&&($3=="emerge")){print $7}' | tail -n1 | sed 's/-[0-9r].*$//')

PORTAGE_LAST_COMPILED_TIME=$(grep -aE -b2 -a4 "AUTOCLEAN: ${PORTAGE_NAME}" /var/log/emerge.log | tail -n7 | sed -n -e 1p -e 7p | awk -F: '{print $1}' | sed 's/[0-9].*-//' | sort -r | sed -r '/$/{N;s/\n/-/}' | bc)

EMERGE_PORTAGE_COMPLETED=$(grep -F -a "${PORTAGE_NAME}-" /var/log/emerge.log | awk '($2==":::"){print $1}'|tail -n1|awk -F: '{print $1}')

et=""
if [ -n "${BUILD_START_TIME_IN_SECONDS}" ]&&[ -n "${EMERGE_PORTAGE_COMPLETED}" ]&&[ ${EMERGE_PORTAGE_COMPLETED} -gt ${BUILD_START_TIME_IN_SECONDS} ]; then 
    et=$( _secondsToUser "$((EMERGE_PORTAGE_COMPLETED-BUILD_START_TIME_IN_SECONDS))" )
else
    EMERGE_PORTAGE_COMPLETED=""
    et=$( _secondsToUser ${PORTAGE_LAST_COMPILED_TIME})
fi

if [ -n "${BUILD_START_TIME_IN_SECONDS}" ]&&[ -z "${EMERGE_PORTAGE_COMPLETED}" ]; then 
    ut=$( _secondsToUser ${ELAPSED_TIME} )
fi

printf "\nPORTAGE NAME:\n\t\t%s\n\nEbuid started at:\n\t\t%s" "${PORTAGE_NAME}" "${BUILD_START_LAST_TIME_FORMATED}"
printf "\n\nElapsed time from start:\n\t\t%s \n\nLast build time:\n\t\t%s\n\n" "$ut" "$et" 

