#!/bin/bash

#
# Program: Checks all PHP files in directory for PSR and show WARNINGS <phpcs_warnings.sh>
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

function usage() {

    printf "\nChecks all PHP files in directory for PSR and show WARNINGS\n"
    printf "\nUsage:\n\t%s -h -d directory_path [-s <standart | list>]\n" "$(basename "$0")"    
    printf "\nExample:\n\t%s -d /path/to/my/project -s PSR12\n\n" "$(basename "$0")"
    exit 1
}

function list_standarts() {
    echo
    phpcs -i
    echo
    exit
}

if (($# == 0)); then
    usage
fi

DIRECTORY_PATH="."
PSR_STANDART="PSR12"

while getopts ":d:hs:" option
do
    case "${option}" in
        d)
            DIRECTORY_PATH=${OPTARG}
            ;;
        h)
            usage
            ;;
        s)
            PSR_STANDART=${OPTARG}
            if [ "$PSR_STANDART" == "list" ]; then
                list_standarts
                exit
            fi
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

if [ -d "${DIRECTORY_PATH}" ]; then
    DIRECTORY_PATH=$(readlink -f $(readlink -f "${DIRECTORY_PATH}"))
    cd "${DIRECTORY_PATH}" || exit
fi

for php_file in $(find . -type d \( -path ./.vscode -o -path ./.history -o -path ./resources -o -path ./bootstrap -o -path ./vendor \) -prune -o -name '*.php')
do
    if [ -d "${php_file}" ]; then
        continue
    fi    
    WARNINGS=$(phpcs --standard=${PSR_STANDART} ${php_file} | grep -E "WARNING\ ")
    if [ -n "${WARNINGS}" ]; then
        echo "phpcs --standard=${PSR_STANDART} ${DIRECTORY_PATH}/${php_file/'./'/}"
        phpcs --standard=${PSR_STANDART} ${php_file} | grep -E "WARNING\ \|"
        echo
    fi
done
