#!/bin/bash

set -eu

trap cleanup EXIT

#
##
get_environment_file() {
    apt -yqq install wget
    wget https://raw.githubusercontent.com/deploy-script/mariadb-adminer/master/.env
}

#
##
setup_environment() {
    # check .env file exists
    if [ ! -f .env ]; then
        get_environment_file
    fi

    # load env file
    set -o allexport
    source .env
    set +o allexport

    echo >&2 "Deploy-Script: [ENV]"
    echo >&2 "$(printenv)"
}

#
##
install_database() {
    debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password password $DB_ROOT_PASSWORD"
    debconf-set-selections <<< "mariadb-server-10.0 mysql-server/root_password_again password $DB_ROOT_PASSWORD"
        
    apt -yqq install mariadb-server
    apt -yqq install mariadb-client
    #
    sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mariadb.conf.d/50-server.cnf
    #
    service mysql start
}

#
##
setup_database() {

    echo >&2 "Deploy-Script: [database] - pausing for database server to start"
    sleep 2

    while ! mysqladmin ping --silent -u"root" -p"$DB_ROOT_PASSWORD"; do
        echo >&2 "Deploy-Script: [database] - waiting for database server to start +5s"
        sleep 5
    done

    echo >&2 "Deploy-Script: [database] - database is up and running"
    sleep 1

    # setup users and database
    echo >&2 "Deploy-Script: [database] - setup users and database"

    mysql -u root -p$DB_ROOT_PASSWORD -e "CREATE DATABASE \`$DB_NAME\` /*\!40100 DEFAULT CHARACTER SET utf8mb4 */;"
    mysql -u root -p$DB_ROOT_PASSWORD -e "CREATE USER IF NOT EXISTS $DB_USER@'%' IDENTIFIED BY '$DB_PASS';"
    mysql -u root -p$DB_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON \`$DB_NAME\`.* TO '$DB_USER'@'%';"
    mysql -u root -p$DB_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES on *.* to 'root'@'localhost' IDENTIFIED BY '$DB_ROOT_PASSWORD';"
    mysql -u root -p$DB_ROOT_PASSWORD -e "FLUSH PRIVILEGES;"
        
    # import database.sql if exists
    if [ -f database.sql ]; then
        echo >&2 "Deploy-Script: [database] - import database file: database.sql"
        cat database.sql | mysql -u root -p"$DB_ROOT_PASSWORD" $DB_NAME
    fi
}

#
##
install_php() {
    apt -y install php$PHP_VERSION php$PHP_VERSION-cli

    apt -y install php$PHP_VERSION-{mbstring,curl,gd,json,xml,mysql,sqlite3,opcache,zip}

    apt -y install libapache2-mod-php$PHP_VERSION
}

#
##
install_apache() {
    apt -yqq install apache2 apache2-utils
    a2enmod headers
    a2enmod rewrite

    htpasswd -b -c /etc/apache2/.htpasswd $ADMINER_USER $ADMINER_PASSWORD

    echo "<VirtualHost *:80>
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

    rm  -f /var/www/html/index.html

    service apache2 restart
}

#
##
install_adminer() {
    #
    wget http://www.adminer.org/latest.php -O /var/www/html/index.php
}

#
##
update_system() {
    #
    apt update
    apt -y upgrade
}

#
##
cleanup() {
    #
    rm -f .env
    rm -f script.sh
}

#
##
main() {
    echo >&2 "Deploy-Script: [OS] $(uname -a)"

    #
    update_system

    #
    setup_environment

    #
    install_database

    #
    setup_database

    #
    install_php

    #
    install_apache

    #
    install_adminer

    #
    cleanup

    echo >&2 "Install completed"
}

# Check is root user
if [[ $EUID -ne 0 ]]; then
    echo "You must be root user to install scripts."
    sudo su
fi

main
