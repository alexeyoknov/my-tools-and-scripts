# my-tools-and-scripts
A small part of the programs and scripts that I have been using in my work since 2008. This repository is in progress 

## PHP Tools
### [PHP PSR Tool](php-psr-scripts)

[phpcs_errors_fix.sh](php-psr-scripts/phpcs_errors_fix.sh) - Checks all PHP files in directory for PSR and fix ERRORS

[phpcs_warnings.sh](php-psr-scripts/phpcs_warnings.sh) - Checks all PHP files in directory for PSR and show WARNINGS

## System Tools
### [Common Linux Scripts](common-linux-scripts)
Common scripts for all Systems

[my-chrooting.sh](common-linux-scripts/my-chrooting.sh) - Chroot (change root system directory)\
[ngrok-http-start.sh](common-linux-scripts/ngrok-http-start.sh) - Create http tunnel to your host via ngrok

### [CentOS Scripts](centos-scripts)
Scripts for CentOS-based systems

[centos-httpd-munin-install.sh](centos-scripts/centos-httpd-munin-install.sh) - Install httpd and munin in CentOS

[centos-in-virtualbox-addons-install.sh](centos-scripts/centos-in-virtualbox-addons-install.sh) - Install VirtualBox additions

### [Gentoo Scripts](gentoo-scripts)
Scripts for Gentoo-based systems like Calculate Linux

[emerge_last_time.sh](gentoo-scripts/emerge_last_time.sh) - Show elapsed time for current compiled portage

[emerge_time.sh](gentoo-scripts/emerge_time.sh) - Show summary build time from last build for options

[layman_add.sh](gentoo-scripts/layman_add.sh) - add gentoo overlay and mask its all packages

### [Ubuntu Scripts](ubuntu-scripts)

[nginx-latest-ubuntu-all.sh](ubuntu-scripts/nginx-latest-ubuntu-all.sh) - installs latest nginx package

## [PDF Tools](pdf-tools)
Tools working with PDF

[pdf-img-downgrade400to300](pdf-tools/pdf-img-downgrade400to300.sh) - reducing pdf size by reducing image density to 300 dpi

[pdf-group-pages](pdf-tools/pdf-group-pages.sh) - groups page numbers by their size. Convenient when printing to different printers

### [PDF Bookmarks](pdf-tools/pdf-bookmarks)

[pdf-dump-metadata](pdf-tools/pdf-bookmarks/pdf-dump-metadata.sh) - export all metadata with bookmarks

[pdf-csvtext-to-metadata](pdf-tools/pdf-bookmarks/pdf-csvtext-to-metadata.sh) - converts ";" to "\n" in file

[pdf-get-metadata](pdf-tools/pdf-bookmarks/pdf-get-metadata.sh)  - get metadata/bookmark form other PDF file

[pdf-update-metadata.sh](pdf-tools/pdf-bookmarks/pdf-update-metadata.sh) - Update metadata/bookmarks in PDF from txt file

## [Media tools](media-tools)
Tools working with media and images

[torrent_file_title_fix](media-tools/torrent_file_title_fix.sh) - changing "Title" to filename in video files using exiftool. Useful for watching series through DNLA on TV. This script calls Transmission when the torrent is completed

## [Windows Tools](windows)
Tools for Windows

[any2png](windows/any2png) - convert/rotate/crop/insert into DXF any image
