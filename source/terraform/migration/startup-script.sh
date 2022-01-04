#! /bin/bash
sudo apt-get update
sudo apt upgrade -y && sudo reboot
sudo apt-get install apache2 php libapache2-mod-php
sudo apt install php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath

echo '<!doctype html><html><body><h1>Kekkoslovakian Joulukortti Ky</h1></body></html>' | tee /var/www/html/index.html