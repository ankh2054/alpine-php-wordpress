#!/bin/sh


# 1.MYSQL SETUP 
#
# ###########

MYSQL_CHARSET=${MYSQL_CHARSET:-"utf8"}
MYSQL_COLLATION=${MYSQL_COLLATION:-"utf8_unicode_ci"}

create_data_dir() {
  echo "Creating /var/lib/mysql"
  mkdir -p /var/lib/mysql
  chmod -R 0700 /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
}

create_run_dir() {
  echo "Creating /run/mysqld"
  mkdir -p /run/mysqld
  chmod -R 0755 /run/mysqld
  chown -R mysql:root /run/mysqld
}

create_log_dir() {
  echo "Creating /var/log/mysql"
  mkdir -p /var/log/mysql
  chmod -R 0755 /var/log/mysql
  chown -R mysql:mysql /var/log/mysql
}

mysql_default_install() {
  if [ ! -d "/var/lib/mysql/mysql" ]; then
      echo "Creating the default database"
 	/usr/bin/mysql_install_db --datadir=/var/lib/mysql
  else
      echo "MySQL database already initialiazed"
  fi
}

create_modx_database() {

  if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then

     # start mysql server.
      echo "Starting Mysql server"
      /usr/bin/mysqld_safe >/dev/null 2>&1 &

     # wait for mysql server to start (max 30 seconds).
      timeout=30
      echo -n "Waiting for database server to accept connections"
      while ! /usr/bin/mysqladmin -u root status >/dev/null 2>&1
      do
        timeout=$(($timeout - 1))
        if [ $timeout -eq 0 ]; then
          echo -e "\nCould not connect to database server. Aborting..."
          exit 1
        fi
        echo -n "."
        sleep 1
      done
      echo
      
      # create database and assign user permissions.
      if [ -n "${DB_NAME}" -a -n "${DB_USER}" -a -n "${DB_PASS}" ]; then
         echo "Creating database \"${DB_NAME}\" and granting access to \"${DB_USER}\" database."
          mysql -uroot  -e  "CREATE DATABASE ${DB_NAME};"
          mysql -uroot  -e  "GRANT USAGE ON *.* TO ${DB_USER}@localhost IDENTIFIED BY '${DB_PASS}';"
          mysql -uroot  -e  "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO ${DB_USER}@localhost;"

      else
        echo "How have not provided all the required ENV variabvles to configure the database"

      fi
  else 
      echo "Database \"${DB_NAME}\" already exists"

  fi
  
}

set_mysql_root_pw() {
    # Check if root password has already been set.
    r=`/usr/bin/mysqladmin -uroot  status`
    if [ ! $? -ne 0 ] ; then
      echo "Setting Mysql root password"
      /usr/bin/mysqladmin -u root password "${ROOT_PWD}"
      
      else 
       echo "Mysql root password already set"
    fi
    
}




[ -f /run-pre.sh ] && /run-pre.sh

chown -R nginx:nginx /DATA

if [ ! -d /DATA/htdocs ] ; then
  mkdir -p /DATA/htdocs
#  chown nginx:nginx /DATA/htdocs
fi


# start php-fpm
mkdir -p /DATA/logs/php-fpm
# start nginx
mkdir -p /DATA/logs/nginx
mkdir -p /tmp/nginx
chown nginx:nginx /tmp/nginx
chown -R nginx:nginx /DATA

if [ ! -d /DATA/bin ] ; then
  mkdir /DATA/bin
  chown nginx:nginx /DATA/bin
  cp /usr/bin/wp-cli /DATA/bin/wp-cli

  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar 
  mv wp-cli.phar /DATA/bin/wp-cli 
fi



php-fpm7
nginx
