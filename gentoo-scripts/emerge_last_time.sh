#!/bin/bash

#
# Program: Show elapsed time for current compiled portage <emerge_last_time.sh>
#
# Author: Alexey Oknov <pitrider at mail dot ru>
# 
# Current Version: 1.1.0
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

PORTAGE_NAME=$1
IS_CURRENT=0
if [ -z "$1" ]; then
    PORTAGE_NAME=$(tail -n20 /var/log/emerge.log | awk '(($2==">>>")&&($3=="emerge")){print $7}' | tail -n1 | sed 's/-[0-9r].*$//')
    IS_CURRENT=1
fi

EMERGE_PORTAGE_COMPLETED=$(grep -F -a "${PORTAGE_NAME}-" /var/log/emerge.log | awk '($2==":::"){print $1}'|tail -n1|awk -F: '{print $1}')

emerge_times=( $(genlop -nt ${PORTAGE_NAME} | grep merge | awk -F: '{print $2}' | sed -e 's/\ hours/*3600+/' -e 's/\ hour/*3600+/' -e 's/\ minutes/*60+/' -e 's/\ minute/*60+/' -e 's/\ and\ //' -e 's/\ second.*//' -e 's/,//g' | bc) )

if [ ${#emerge_times[@]} -gt 0 ]; then
    PORTAGE_LAST_COMPILED_TIME=${emerge_times[${#emerge_times[@]}-1]}
else
    PORTAGE_LAST_COMPILED_TIME=0
fi

PORTAGE_BUILD_TIME_MAX=0
PORTAGE_BUILD_TIME_MIN=${PORTAGE_LAST_COMPILED_TIME}

for emerge_time in ${emerge_times[@]}
do
    if [ ${PORTAGE_BUILD_TIME_MAX} -le ${emerge_time} ]; then
        PORTAGE_BUILD_TIME_MAX=${emerge_time}
    fi
    if [ ${PORTAGE_BUILD_TIME_MIN} -gt ${emerge_time} ] || [ ${PORTAGE_BUILD_TIME_MIN} -eq 0 ]; then
        PORTAGE_BUILD_TIME_MIN=${emerge_time}
    fi
done

PBT_MIN=$( _secondsToUser ${PORTAGE_BUILD_TIME_MIN})
PBT_MAX=$( _secondsToUser ${PORTAGE_BUILD_TIME_MAX})

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

printf "\nPORTAGE NAME:\n\t\t%s\n" "${PORTAGE_NAME}"
if [ ${IS_CURRENT} -eq 1 ]; then
    printf "\nEbuid started at:\n\t\t%s" "${BUILD_START_LAST_TIME_FORMATED}"
    printf "\n\nElapsed time from start:\n\t\t%s\n" "$ut" 
fi
printf "\nMin build time:\n\t\t%s \n\nMax build time:\n\t\t%s" "${PBT_MIN}" "${PBT_MAX}" 
printf "\n\nLast build time:\n\t\t%s\n\n" "$et"


