#!/bin/bash

#
# Program: groups page numbers by their size <pdfpages.sh>
#
# Author: Alexey Oknov <pitrider at mail dot ru>
# 
# Current Version: 1.0.0 (03 Sep 2019)
# 
# License:
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#

function checkAndDel () {
	if [ -f "$1" ]; then
		rm -f "$1"
	fi
}


IFS=$'\n'

CUR_DATE=$(date "+%Y%m%d_%H%M%s")
TMP_PATH="${HOME}/tmp"
TMP_FILE="${TMP_PATH}/${CUR_DATE}"
PDF_FILE="$1"
PDF_PAGES_INFO="${PDF_FILE%.*}"_pdfpages.txt
GROUPED_PAGES=""

#offset in points for scanned pages with auto-detection page sizes
#in this case, the A4 page size (210mm x 297mm) can be 212mm x 295mm
LIMIT_OFFSET=7

NEED_ZENITY=0
if [ ! -f "${PDF_FILE}" ]; then
	if [ ! -f $(which zenity) ] || [ -t 0 ]; then
		echo
		printf "Usage:\n\t%s <file.pdf>\n" "$(basename $0)"
		echo
		exit 1
	else
		PDF_FILE=$(zenity --title="Выбор PDF" --file-selection --file-filter=*.[pP][dD][fF])
		NEED_ZENITY=1
		if [ -z "${PDF_FILE}" ]; then
			exit 1
		fi
	fi 
fi

#aWmm=(210 297 420 596 841 297 420 596 841 1189)
#aHmm=(297 420 596 841 1189 210 297 420 596 841)

#sizes in points
aW=(595 842 1191 1689 2384 842 1191 1689 2384 3370)
aH=(842 1191 1689 2384 3370 595 842 1191 1689 2384)

#page names
aTxt=("A4" "A3" "A2" "A1" "A0" "A4" "A3" "A2" "A1" "A0")

#page layout
aDesc=("portrait" "portrait" "portrait" "portrait" "portrait" "album" "album" "album" "album" "album")

#get the number of pages in pdf
PDF_PAGES_COUNT=$(pdfinfo "${PDF_FILE}" | grep -a Pages| awk '{print $2}')

#export info about all pages to the tmpfile
pdfinfo -f 1 -l ${PDF_PAGES_COUNT} "${PDF_FILE}" | grep -a Page | grep -n size \
	| awk '{print NR" "$4" x "$6}'>"${TMP_FILE}"

#get count of exported pages
PAGES_COUNT=$(wc -l "${TMP_FILE}" | awk '{print $1}')

i_=0;
while [ ${PAGES_COUNT} -gt 0 ]
do
	if [ $i_ -lt ${#aW[@]} ]; then #find all standart pages in PDF
		w=${aW[$i_]}
		h=${aH[$i_]}
		PAGE_DESC=${aTxt[$i_]}"("${aDesc[$i_]}")"
		i_=$((i_+1))
	else
		w=$(head -n1 "${TMP_FILE}" | awk '{print $2}')
		h=$(head -n1 "${TMP_FILE}" | awk '{print $4}')
		PAGE_DESC="unknown"
	fi
	FOUNDED_PAGES=$(awk -v w="$w" -v h="$h" -v offset=${LIMIT_OFFSET} \
		' (($2>=(w-offset)&&($2<=(w+offset))) \
		&& ($4>=(h-offset)&&($4<=(h+offset)))){print $1}' "${TMP_FILE}" | tr '\n' ',')

	if [ -z "${FOUNDED_PAGES}" ]; then
		continue
	fi
	start_index=$(echo ${FOUNDED_PAGES} | awk -F, '{print $1}')
	page_num=${start_index}
	end_index=$(echo ${FOUNDED_PAGES}  | awk -F, '{print $(NF-1)}')

	GROUPED_PAGE="";
	for current_page_index in $(seq ${start_index} ${end_index}); do
		pages=$(echo ${FOUNDED_PAGES} | grep ",${current_page_index},")
		if [ ${page_num} -eq 0 ]; then
			if [ -n "${pages}" ]; then
				page_num="${current_page_index}"
			else
				continue
			fi 
		fi
		if [ -z "${pages}" ]; then
			previous_page_index=$((current_page_index-1)) 
			if [ ${page_num} -ge ${previous_page_index} ]; then
				GROUPED_PAGE="${GROUPED_PAGE},${page_num},"
				else
					GROUPED_PAGE="${GROUPED_PAGE},${page_num}-${previous_page_index},"
			fi
			page_num=0 
		fi
	done
	if [ ${page_num} -ne ${current_page_index} ]; then
		GROUPED_PAGE="${GROUPED_PAGE},${page_num}-${current_page_index},"
		else
			GROUPED_PAGE="${GROUPED_PAGE},${page_num},"
	fi
	GROUPED_PAGE=$(echo "${GROUPED_PAGE}" | sed -e "s/,,/,/g" -e "s/,//" -e "s/,$//" -e "s/,0[0-9.-]*$//g")
	
	wmm=$(printf "%.2f" $(echo "$w*0.352777778"|bc))
	hmm=$(printf "%.2f" $(echo "$h*0.352777778"|bc))
	wh="$wmm x $hmm"

	GROUPED_PAGES=${GROUPED_PAGES}$(printf "%20s%20s:\t%s;" "$wh" ${PAGE_DESC} "${GROUPED_PAGE}")

	#get a new list of remaining pages
	awk -v w="$w" -v h="$h" -v offset=${LIMIT_OFFSET} \
		'(($2<=(w-offset)||($2>=(w+offset)))\
		||($4<=(h-offset)||($4>=(h+offset)))){print $1" "$2" x "$4}' "${TMP_FILE}" \
		>"${TMP_FILE}2"

	mv "${TMP_FILE}2" "${TMP_FILE}"

	#get a new number of pages
	PAGES_COUNT=$(wc -l "${TMP_FILE}" | awk '{print $1}')
done

checkAndDel "${PDF_PAGES_INFO}"

echo "${GROUPED_PAGES}" | tr ';' '\n' > "${PDF_PAGES_INFO}"

if [ ${NEED_ZENITY} -eq 1 ]; then
	zenity --info --title="pdf-group-pages" --text="Grouped pages are saved in the ${PDF_PAGES_INFO} file"
fi

checkAndDel "${TMP_FILE}"


