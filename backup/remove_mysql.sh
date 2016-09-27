#!/usr/bin/env bash
rm -rf /usr/local/mysql*
rm -rf /etc/my.cnf
rm -rf /lib/systemd/system/mysql.service
sed -i "s/\/use\/local\/mysql\/lib//g" /etc/ld.so.conf