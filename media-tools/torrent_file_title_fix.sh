#!/bin/bash

#
# Program: changing "Title" to filename in video files <pdfpages.sh>
# Useful for watching series through DNLA on TV. 
# This script calls Transmission when the torrent is completed 
#
# Author: Alexey Oknov <pitrider at mail dot ru>
# 
# License:
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

TORRENT_FILE="$TR_TORRENT_DIR/$TR_TORRENT_NAME"

if [ -d "${TORRENT_FILE}" ]; then
    chmod 6775 -R "${TORRENT_FILE}"
    chown root:users -R "${TORRENT_FILE}"

	cd "${TORRENT_FILE}" || exit
	for file_name in $(ls -1 "${TORRENT_FILE}")
	do
		TITLE=$(exiftool "${file_name}" | grep Title | awk -F: '{print $2}')

		if [ -n "${TITLE}" ]; then
			SEASON_EPISODE=$(echo "${file_name}" | sed -e 's/^.*\([sS][0-9]\)/\1/g' -e 's/\..*//')
			NEW_TITLE=""
			if [ -n "${SEASON_EPISODE}" ] ;then
				NEW_TITLE="${SEASON_EPISODE} -${TITLE}"
			
				exiftool -overwrite_original_in_place -title="${NEW_TITLE}" "${file_name}"
			fi
		fi
	
	done
else
    chmod 6755 "${TORRENT_FILE}"
    chown root:users "${TORRENT_FILE}"

	TITLE=$(exiftool "${TORRENT_FILE}" | grep Title | awk -F: '{print $2}')

	if [ -n "$TITLE" ]; then
		NEW_TITLE=""
		SEASON_EPISODE=$(echo "${TORRENT_FILE}" | sed -e 's/^.*\([sS][0-9]\)/\1/g' -e 's/\..*//')
		if [ -n "${SEASON_EPISODE}" ]; then
			NEW_TITLE="${SEASON_EPISODE} -${TITLE}"

			exiftool -overwrite_original_in_place -title="${NEW_TITLE}" "${TORRENT_FILE}"
		fi
	fi

fi
