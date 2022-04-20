#!/bin/bash

#convert Title;BookmarkLevel;PageNumber 

IFS=$'\n'

sed -e 's/^/BookmarkBegin\nBookmarkTitle:\ /' -e 's/;/\nBookmarkLevel:/' -e 's/;/\nBookmarkPageNumber:/' "$1" > "${1%.*}"_fixedmetadata.txt