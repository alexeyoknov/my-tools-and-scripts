#!/bin/bash

#
# Program: Update metadata/bookmarks in PDF from txt file <pdf-update-metadata.sh>
#
# Author: Alexey Oknov <pitrider at mail dot ru>
# 
# Current Version: 1.0.0 (31 Mar 2017)
#
# License:
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#


IFS=$'\n'

PDF_FILE=""
TXT_FILE=""
OUTPUT_PDF=""

function usage() {
    printf "\nThis program updates metadata/bookmarks in PDF from __dumped.txt file\n"
    printf "\nUsage:\n\t%s -f <pdf filename> [-o <output_pdf_file>]" "$(basename "$0")"
    printf "\n\n\t-f\tinput pdf file\n\t\tMetadata gets from <pdf filename>__dumped.txt"
	printf "\n\n\t-o\toutput pdf file name"
    printf "\n\nExample:\n\t%s -f myfile.pdf -o myfile-updated-bookmarks.pdf\n\n" "$(basename "$0")"
    exit 1
}

if (($# == 0)); then
    usage
fi

while getopts ":f:o:" option
do
    case "${option}" in
        f)
            PDF_FILE=${OPTARG}
            TXT_FILE="${PDF_FILE%.*}"_dumped.txt
            ;;
        o)
            OUTPUT_PDF=${OPTARG}
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

if [ ! -f "${PDF_FILE}" ]; then
    echo
    echo "ERROR: File ${PDF_FILE} not found"
    echo
    exit 1
fi

if [ ! -f "${TXT_FILE}" ]; then
    echo
    echo "ERROR: File ${TXT_FILE} not found"
    echo
    usage
    exit 2
fi

if [ -z "${OUTPUT_PDF}" ]; then
    OUTPUT_PDF="${PDF_FILE%.*}"_fixed_metadata.pdf
fi

pdftk "${PDF_FILE}" update_info_utf8 "${TXT_FILE}" output "${OUTPUT_PDF}"
