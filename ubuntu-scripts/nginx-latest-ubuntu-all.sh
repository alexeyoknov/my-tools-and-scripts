#!/bin/bash

#
# Program: Update nginx to latest stable for Ubuntu all <nginx-latest-ubuntu-all.sh>
#


if [ $(id -g) -gt 0 ]; then 
    echo
    echo "Run this script as root or via sudo"
    echo    
    exit 1
fi

apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null

gpg --dry-run --quiet --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu $(lsb_release -cs) nginx" \
    | tee /etc/apt/sources.list.d/nginx.list

echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | tee /etc/apt/preferences.d/99nginx

sudo apt-get remove nginx nginx-common
sudo apt-get update
sudo apt-get install nginx
sudo service nginx start