#!/bin/bash

pdftk "$1" dump_data_utf8 > "${1%.*}"_dumped.txt

