#!/bin/bash
#
# Program: Reducing pdf size by reducing image density to 300dpi for JPG
#          and 400dpi for OTHER formats <pdf-img-downgrade400to300.sh>
#
# Author: Alexey Oknov <pitrider at mail dot ru>
# 
# Current Version: 1.0.0 (13 Nov 2019)
#
# License:
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

PDF_FILE=""
PDF_FILE_NAME=""
TEMP_DIR=""
ROTATE=""
OUTPUT_PDF=""
KEEP_TEMP_IMAGES=0
CURRENT_DIR=$(pwd)

function usage() {
    printf "\nThis program reduces pdf size by reducing image density to 300dpi for JPG and 400dpi for OTHER\n"
    printf "\nUsage:\n\t%s -f <pdf-filename> [-r <rotate pages in degrees> [-k] [-o <output_pdf_file>]]\n" "$(basename "$0")"
	printf "\n\t-f\tinput pdf file"
	printf "\n\t-r\trotate pages in degrees"
	printf "\n\t-k\tkeep temporary files"
	printf "\n\t-o\toutput pdf file name"
	printf "\n\n"
    exit 1
}

if (($# == 0)); then
    usage
fi

while getopts ":f:ko:r:" option
do
    case "${option}" in
        f)
            PDF_FILE=${OPTARG}
            PDF_FILE_NAME=${PDF_FILE%.*}
			TEMP_DIR=${PDF_FILE_NAME}
            ;;
		k)
			KEEP_TEMP_IMAGES=1
			;;
        o)
            OUTPUT_PDF=${OPTARG}
            ;;
		r)
			ROTATE="-rotate ${OPTARG}"
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

if [ -z "${PDF_FILE}" ]; then
	usage
	exit
fi

if [ -z "${TEMP_DIR}" ]; then
	usage
	exit
fi

if [ -z "${OUTPUT_PDF}" ]; then
	OUTPUT_PDF="${PDF_FILE_NAME}"_fixed.pdf
fi

if [ -d "${TEMP_DIR}" ]; then
	rm -rf "./${TEMP_DIR}"
fi 

mkdir "${TEMP_DIR}"

cp "${PDF_FILE}" "${TEMP_DIR}"/

cd "${TEMP_DIR}" || exit

pdfimages -png -j "${PDF_FILE}" pgs-

mkdir ./300dpi

for IMAGE_FILE in $(ls -1 pgs-*)
do
	IMAGE_RESOLUTION=$(identify -format "%x" ${IMAGE_FILE})
	SCALE_PERCENT=$((300*100/IMAGE_RESOLUTION))"%"
	IMAGE_EXT=$(echo ${IMAGE_FILE##*.} | tr 'A-Z' 'a-z')
	cp ${IMAGE_FILE} "300dpi"/${IMAGE_FILE}
	if [ "${IMAGE_EXT}" != "jpg" ]; then
		if [ "${IMAGE_EXT}" == "png" ]; then
		 PAGE_NUMBER=$(echo ${IMAGE_FILE%.*} | sed -e 's/pgs-[0\t]*//')
		 PAGE_NUMBER=$((PAGE_NUMBER+1))
		 PAGE_INFO=$(pdfimages -f ${PAGE_NUMBER} -l ${PAGE_NUMBER} -list ${PDF_FILE} | tail -n1)
		 x=$(echo ${PAGE_INFO} | awk '{print $13}')
		 PNG_RESOLUTION=$((x/10*10))
		 SCALE_PERCENT=$((400*100/${PNG_RESOLUTION}))"%"
		 mogrify -density 400 -units pixelsperinch -scale ${SCALE_PERCENT} "300dpi/${IMAGE_FILE}"
		 convert "300dpi"/"${IMAGE_FILE}" "300dpi"/"${IMAGE_FILE%.*}".pdf
		fi
		continue
	fi
	mogrify -density 300 -units pixelsperinch -scale ${SCALE_PERCENT}  ${ROTATE} "300dpi/${IMAGE_FILE}"
	convert "300dpi"/"${IMAGE_FILE}" "300dpi"/"${IMAGE_FILE%.*}".pdf
done

cd "${CURRENT_DIR}" || exit
pdftk "${TEMP_DIR}"/300dpi/pgs-*.pdf output "${OUTPUT_PDF}"

if [ ${KEEP_TEMP_IMAGES} -eq 0 ]; then
	rm -rf ./"${TEMP_DIR}"
fi

echo "All done"
echo




