# mariadb-adminer

This script deploys a MariaDB server for stand alone use (container), it runs 
Apache2 to serve Adminer which is accessable though Basic Auth at http://127.0.0.1/
or though a domain etc.

## :clipboard: Features

Here is whats installed:

 - PHP7.4 with mbstring, curl, gd, json, xml, mysql, sqlite3, opcache, zip
 - Apache2
 - MariaDB
 - Adminer
 
Adminer is accessable though web

## :arrow_forward: Install

Should be done on a **clean ubuntu 20.04 server**!

```
wget https://raw.githubusercontent.com/deploy-script/mariadb-adminer/master/script.sh && bash script.sh
```

## :lock: Credentials

 See `.env` file
