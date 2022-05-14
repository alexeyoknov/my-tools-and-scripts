#!/bin/bash

#
# Program: Create http tunnel to your host via ngrok <ngrok-http-start.sh>
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

NGROK="/usr/bin/ngrok"
PORT="80"
HOST="127.0.0.1"

PORT_RE='^[0-9]+$'
DOMAIN_NAME_RE='^((http[s]?:\/\/)?)(([a-z0-9]([\w-]*)?[a-z0-9]))((\.[a-z0-9]([\w-]*?)[a-z0-9])+?)((:\d{2,})?)(((\/[\w%]*)?)*)(\.\w*)?((\?[a-zA-Z][\w]*=[\w%]*(&[a-zA-Z][\w]*=[\w%]*)*)?)(#[\w-]*)?\s*?$'
DOMAIN_IP_RE='[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$'

function usage() {
    printf "\nThis program create http tunnel to your host via ngrok\n"
    printf "\nUsage:\n\t%s [-H <host>] [-p <port>]" "$(basename "$0")"
    printf "\n\n\t-H\thost, default is 127.0.0.1\n\n"
    printf "\t-p\tport, default is 80\n\n"
    printf "\t-h\tshow this help\n\n"
    printf "\nExample:\n\t%s -H 192.168.0.107 -p 9000\n\n" "$(basename "$0")"
    exit 1
}

if [ ! -f "${NGROK}" ]; then
  echo "Please, install/put ngrok into /usr/bin/ path"
  exit 2
fi

while getopts ":hH:p:" option
do
    case "${option}" in
        h)
            usage
            ;;
        H)
            h=""
            h=$(echo ${OPTARG} | grep -P "$DOMAIN_NAME_RE")
            if [ -n "$h" ]; then
                h="${OPTARG}"
            else            
                h=$(echo ${OPTARG} | grep -P "$DOMAIN_IP_RE")
                if [ -n "$h" ]; then
                  h="${OPTARG}"
                fi
            fi
            if [ -n "$h" ]; then
                HOST=${OPTARG}
            fi
            ;;
        p)
            if [[ "${OPTARG}" =~ ${PORT_RE} ]]; then
               PORT="${OPTARG}"
            fi
            ;;
        *)
            ;;
    esac
done

echo "Host: ${HOST}"
echo "Port: ${PORT}"

${NGROK} http "${HOST}:${PORT}"

