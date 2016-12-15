#!/usr/bin/env bash

set -x

source config.sh

function usage() { 
    printf "usage: ./clean.sh [--deps] [--depends] [--dependency]\n"
    printf "                  [--redis]\n"
    printf "                  [--mysql]\n"
    printf "                  [--php]\n"
    printf "                  [--nginx]\n"
    printf "     --deps | --depends | --dependency     remove installed dependency\n"
    printf "     --redis      remove redis\n"
    printf "     --mysql      remove mysql\n"
    printf "     --php        remove php\n"
    printf "     --nginx      remove nginx\n"
    printf "     --all        remove everything downloaded and installed\n"
    exit 1
}

if [ "$1" == "" ]; then
    usage
fi

# Attention! 
# rm -rf ${variable}, if nothing after ${variable}, make sure that ${variable} is what you need.

while [ "$1" != "" ]; do
    case $1 in
        --deps | deps | --depends | depends | --dependency | dependency )
            # delete installed dependency
            yum remove net-tools wget gcc autoconf bzip2 libaio pcre-devel make \
                zlib-devel libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel freetype-devel openldap-devel \
                libmcrypt-devel epel-release libmcrypt-devel.x86_64
            ;;
        --redis | redis )
            rm -rf ${save_path}/redis*
            rm -rf /usr/local/redis*
            rm -f ${service_path}/redis.service
            ;;
        --mysql | mysql )
            rm -rf ${save_path}/mysql*
            rm -rf /usr/local/mysql*
            rm -f /etc/my.cnf
            rm -f ~/mysql_initialize
            rm -f ${service_path}/mysql.service
            ;;
        --php | php )
            rm -rf ${save_path}/php*
            rm -rf /usr/local/php*
            ;;
        --nginx | nginx )
            rm -rf ${save_path}/nginx*
            rm -rf /usr/local/nginx*
            rm -f ${service_path}/nginx.service
            rm -f /usr/local/bin/nginx
            ;;
        --all | all )
            # remove everything
            set -- "--all" "--deps" "--redis" "--mysql" "--php" "--nginx" "--end"
            ;;
        --help | help )
            usage
            exit
            ;;
        --end | end )
            exit
            ;;
            * )
            usage
            exit
            ;;
    esac
    shift
done