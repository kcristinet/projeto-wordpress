#!/bin/bash

# Update and install necessary packages
sudo apt-get update
sudo apt-get install -y apache2 mysql-server php php-mysql libapache2-mod-php php-cli

# Download and install WordPress
wget -c http://wordpress.org/latest.zip
tar -xzvf latest.tar.gz
sudo mv wordpress/* /var/www/html/

# Set permissions
sudo chown -R www-data:www-data /var/www/html/
sudo chmod -R 755 /var/www/html/

# Configure MySQL
sudo mysql -u root -e "CREATE DATABASE wordpress;"
sudo mysql -u root -e "CREATE USER 'wordpressuser'@'localhost' IDENTIFIED BY 'password';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpressuser'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"

# Configure WordPress
sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo sed -i "s/db-wordpress/wordpress/" /var/www/html/wp-config.php
sudo sed -i "s/"testadmin"/wordpressuser/" /var/www/html/wp-config.php
sudo sed -i "s/"NaoSeiaSenha!"/password/" /var/www/html/wp-config.php

# Restart Apache
sudo systemctl restart apache2