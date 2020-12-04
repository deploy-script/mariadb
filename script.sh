#!/bin/bash

set -o allexport
source .env
set +o allexport

#
sudo apt update
sudo apt -y upgrade

#
sudo debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password password $DB_ROOT_PASSWORD"
sudo debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password_again password $DB_ROOT_PASSWORD"
    
sudo apt -yqq install mariadb-server
sudo apt -yqq install mariadb-client
#
sudo sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
#
sudo service mysql start
#
sudo mysql -u root -p$DB_ROOT_PASSWORD -e "CREATE DATABASE $DB_NAME /*\!40100 DEFAULT CHARACTER SET utf8 */;"
sudo mysql -u root -p$DB_ROOT_PASSWORD -e "CREATE USER $DB_USER@'%' IDENTIFIED BY '$DB_PASS';"
sudo mysql -u root -p$DB_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';"
sudo mysql -u root -p$DB_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';"
sudo mysql -u root -p$DB_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"

#
sudo apt -yqq install apache2 apache2-utils
sudo a2enmod headers
sudo a2enmod rewrite

sudo htpasswd -b -c /etc/apache2/.htpasswd $ADMINER_USER $ADMINER_PASSWORD

sudo echo "<VirtualHost *:80>
        ServerAdmin $SERVER_EMAIL
        DocumentRoot /var/www/html
        ErrorLog \${APACHE_LOG_DIR}/error.log
        CustomLog \${APACHE_LOG_DIR}/access.log combined

    <Directory \"/var/www/html\">
        AuthType Basic
        AuthName \"Restricted Access\"
        AuthUserFile /etc/apache2/.htpasswd
        Require valid-user
    </Directory>
</VirtualHost>
" > /etc/apache2/sites-enabled/000-default.conf

sudo rm  -f /var/www/html/index.html

sudo apt -y install php$PHP_VERSION php$PHP_VERSION-cli

sudo apt -y install php$PHP_VERSION-{mbstring,curl,gd,json,xml,mysql,sqlite3,opcache,zip}
sudo apt -y install php-mysql

sudo apt -y install libapache2-mod-php$PHP_VERSION

sudo service apache2 restart

sudo wget http://www.adminer.org/latest.php -O /var/www/html/index.php
