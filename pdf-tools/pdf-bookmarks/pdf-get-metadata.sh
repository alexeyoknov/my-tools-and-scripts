#!/bin/bash

#
# Program: Update metadata/bookmarks in PDF from another PDF file <pdf-get-metadata.sh>
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

SOURCE_PDF_FILE=""
DEST_PDF_FILE=""
TXT_FILE=""
OUTPUT_PDF=""
KEEP_TXT=0

function usage() {
    printf "\nThis program updates metadata/bookmarks in PDF from another PDF file\n"
    printf "\nUsage:\n\t%s -d <original pdf file> -s <pdf file with metadata> [-k] [-o <output_pdf_file>]\n" "$(basename "$0")"
    printf "\n\t-k\tkeep (don't remove) txt file with metadata"
    printf "\n\t-o\toutput pdf file name"
    printf "\n\nExample:\n\t%s -d myfile.pdf -s file-with-bookmarks.pdf -k -o myfile-with-bookmarks.pdf" "$(basename "$0")"
    printf "\n\n"
    exit 1
}

if (($# == 0)); then
    usage
fi

while getopts ":d:ko:s:" option
do
    case "${option}" in
        d)
            DEST_PDF_FILE=${OPTARG}
            TXT_FILE="${DEST_PDF_FILE%.*}"_dumped.txt
            ;;
        k)
            KEEP_TXT=1
            ;;
        o)
            OUTPUT_PDF=${OPTARG}
            ;;  
        s)
            SOURCE_PDF_FILE=${OPTARG}
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

if [ ! -f "${DEST_PDF_FILE}" ] || [ ! -f "${SOURCE_PDF_FILE}" ]; then
    usage
    exit 1
fi

if [ -z "${OUTPUT_PDF}" ]; then
    OUTPUT_PDF="${DEST_PDF_FILE%.*}"_fixed_metadata.pdf
fi

pdftk "${SOURCE_PDF_FILE}" dump_data_utf8 > "${TXT_FILE}"
pdftk "${DEST_PDF_FILE}" update_info_utf8 "${TXT_FILE}" output "${OUTPUT_PDF}"

if [ $KEEP_TXT -eq 0 ] && [ -f "${TXT_FILE}" ]; then
    rm -f "${TXT_FILE}"
fi
