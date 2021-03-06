#!/usr/bin/env bash
set -x
set -e
sudo service mysql stop || echo "mysql not stopped"
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo  mysqld_safe &
sleep 16
sudo mysql -e "GRANT ALL PRIVILEGES ON openredu_test.* to 'travis'@'%';"
sudo service mysql restart || echo "mysql failed to restart"
sleep 16
