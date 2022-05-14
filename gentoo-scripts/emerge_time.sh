#!/bin/bash

#
# Program: Show summary build time from last build <emerge_time.sh>
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

function checkex()
{
    EXCLUDED_PACKAGES_LIST=""
    if [ -n "${EXCLUDED_PACKAGES}" ]; then
        EXCLUDED_PACKAGES_LIST=" --exclude ""${EXCLUDED_PACKAGES//','/' --exclude '}"
    fi
}

function _secondsToUser() {
    local TIME_IN_SECONDS="$1"
    
    h="$((TIME_IN_SECONDS/3600))"
    m="$(((TIME_IN_SECONDS-h*3600)/60))"
    s="$((TIME_IN_SECONDS-h*3600-m*60))" 
    echo "$h hours $m minutes $s seconds"
}

SUM_TIME=0

function usage() {
    printf "\nThis program shows summary build time from last build\n"
    printf "\nUsage:\n\t%s -a <action> [-p <portage_name> || -f <filename> || -c [-x <excluded packages>]]" "$(basename "$0")"
    printf "\n\n\t-a\taction"
    printf "\n\n\tWhere <action> are:\n\n"
    printf "\tdeep\n\t\tget packages list from 'emerge -pvuDN @world'\n\n"
    printf "\tworld\n\t\tget packages list from 'emerge -pvuN @world'\n\n"
    printf "\tpreserved\n\t\tget packages list from 'emerge -pv @preserved-rebuild'\n\n"
    printf "\tsystem\n\t\tget packages list from 'emerge -pv @system'\n\n"
    printf "\tsystemE\n\t\tget packages list from 'emerge -pve @system'\n\n"
    printf "\tportage <portage>\n\t\tget packages list from 'genlop -t <portage_name>'\n\n"
    printf "\tfromfile <filename>\n\t\tget packages list from <filename>\n\n"
    printf "\tall\n\t\tget packages list from 'eix -Icn | egrep \"\\[U|\\[D\"'\n\n"

    printf "\t-c\tcompile packages\n"
    printf "\t-x\texclude packages\n"

    printf "\nExample:\n\t%s -a all -c -e gcc,calculate-sources\n\n" "$(basename "$0")"
    exit 1
}

NEED_COMPILE=0
EXCLUDED_PACKAGES=""
EXCLUDED_PACKAGES_LIST=""
PACKAGES_LIST=""
PORTAGE_NAME=""
FILE_NAME=""

if (($# == 0)); then
    usage
fi


while getopts ":a:cf:p:e:h" option
do
    case "${option}" in
        a)
            ACTION=${OPTARG}
            ;;
        c)
            NEED_COMPILE=1
            ;;
        f)
            FILE_NAME=${OPTARG}
            ;;
        p)
            PORTAGE_NAME=${OPTARG}
            ;;
        e)
            EXCLUDED_PACKAGES=${OPTARG}
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

checkex

case "${ACTION}" in 
    "deep")
            PACKAGES_LIST="-vuDN --digest @world"
            portage_list=($(emerge -p ${PACKAGES_LIST} ${EXCLUDED_PACKAGES_LIST} | grep -E "\[ebuild|\[binary"|awk '{print $4}'|awk -F: '{print $1}' | sed -e "s/-[0-9._a-z:]*$//g" -e "s/-[0-9.]*$//g"))
            ;;
    "world")
            PACKAGES_LIST="-vuN --digest @world"
            portage_list=($(emerge -p ${PACKAGES_LIST} ${EXCLUDED_PACKAGES_LIST} | grep -E "\[ebuild|\[binary"|awk '{print $4}'|awk -F: '{print $1}' | sed -e "s/-[0-9._a-z:]*$//g" -e "s/-[0-9.]*$//g"))
            ;;
    "preserved")
            PACKAGES_LIST="-v --digest @preserved-rebuild"
            portage_list=($(emerge -p ${PACKAGES_LIST} ${EXCLUDED_PACKAGES_LIST} | grep -E "\[ebuild|\[binary"|awk '{print $4}'|awk -F: '{print $1}' | sed -e "s/-[0-9._a-z:]*$//g" -e "s/-[0-9.]*$//g"))
            ;;
    "system")
            PACKAGES_LIST="-v --digest @system"
            portage_list=($(emerge -p ${PACKAGES_LIST} ${EXCLUDED_PACKAGES_LIST}| grep -E "\[ebuild|\[binary"|awk '{print $4}'|awk -F: '{print $1}' | sed -e "s/-[0-9._a-z:]*$//g" -e "s/-[0-9.]*$//g"))
            ;;
    "systemE")
            PACKAGES_LIST="-ve --digest @system"
            portage_list=($(emerge -p ${PACKAGES_LIST} ${EXCLUDED_PACKAGES_LIST}| grep -E "\[ebuild|\[binary"|awk '{print $4}'|awk -F: '{print $1}' | sed -e "s/-[0-9._a-z:]*$//g" -e "s/-[0-9.]*$//g"))
            ;;
    "portage")
            PACKAGES_LIST="${PORTAGE_NAME}"
            portage_list=("${PORTAGE_NAME}")
            ;;
    "fromfile")
            PACKAGES_LIST="-v \`cat \${FILE_NAME}\`"
            portage_list=( $(cat "${FILE_NAME}") )
            ;;
    "all")        
            portage_list=($(eix -Icn|grep -E "\[U|\[D"|awk '{print $2}'))
            PACKAGES_LIST="-v ${portage_list[*]}"
            ;;

esac

fdel=""
for del in ${EXCLUDED_PACKAGES//','/' '}
do
    fdel=$(printf -- '%s\n' ${portage_list[*]} | grep ${del})
    if [ -n "${fdel}" ]; then
        portage_list=(${portage_list[*]/${fdel}})
    fi
done

echo

for portage in ${portage_list[*]}
do 

    PORTAGE_LAST_COMPILED_TIME=$(grep -aE -b2 -a4 "AUTOCLEAN: ${portage}" /var/log/emerge.log | tail -n7 | sed -n -e 1p -e 7p | awk -F: '{print $1}' | sed 's/[0-9].*-//' | sort -r | sed -r '/$/{N;s/\n/-/}' | bc)
    if [ -n "${EMERGE_START}" ]&&[ -n "${EMERGE_COMPILED}" ]&&[ ${EMERGE_COMPILED} -gt ${EMERGE_START} ]; then
	    SUM_TIME="$((SUM_TIME+PORTAGE_LAST_COMPILED_TIME))"
        printf "%10d\t%s\n" "${PORTAGE_LAST_COMPILED_TIME}" "${portage}"
    fi
done

printf "\n%d packages: %s\n\n" ${#portage_list[@]} $( _secondsToUser ${SUM_TIME} )

if [ ${NEED_COMPILE} -eq 1 ]; then
  
    if [ "${ACTION}" == "all" ]; then
        PACKAGES_LIST="-v ${portage_list[*]}"
    fi 

    emerge --keep-going -aq1 ${EXCLUDED_PACKAGES_LIST} ${PACKAGES_LIST}
fi
