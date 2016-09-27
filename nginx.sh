#!/usr/bin/env bash
# NLS nuisances.
LC_ALL=C
export LC_ALL
LANGUAGE=C
export LANGUAGE

shell_script_path=$(pwd)
profile_file=/etc/profile
service_path=/lib/systemd/system

save_path=/root/downloads
package_prefix=/root/downloads

install_log=install.log

# if you have needed packages, type the path behind
mysql_path=${package_prefix}/mysql-5.7.15-linux-glibc2.5-x86_64.tar
php_path=${package_prefix}/php-7.0.11.tar.bz2
redis_path=${package_prefix}/redis-stable.tar.gz
nginx_path=${package_prefix}/nginx-1.11.4.tar.gz

# packages download's url
mysql_pkg_url=http://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.15-linux-glibc2.5-x86_64.tar
php_pkg_url=http://cn2.php.net/get/php-7.0.11.tar.bz2/from/this/mirror
redis_pkg_url=http://download.redis.io/redis-stable.tar.gz
nginx_pkg_url=http://nginx.org/download/nginx-1.11.4.tar.gz

# get file name with file extension
mysql_pkg_name=$(echo ${mysql_pkg_url} | awk -F '/' '{print $NF}')
php_pkg_name=$(echo ${php_pkg_url} | awk -F '/' '{print $5}')
redis_pkg_name=$(echo ${redis_pkg_url} | awk -F '/' '{print $NF}')
nginx_pkg_name=$(echo ${nginx_pkg_url} | awk -F '/' '{print $NF}')

# add some environment variable
function add_env() {
    path=$1
    printf "\nexport PATH=$1:\$PATH\n" >> ${profile_file}
    source ${profile_file}
    return 0
}

# get the correct directory name after unpacked
function get_unpacked_name(){
    filename=$1
    extension="${filename##*.}"
    while true
    do
        if [[ ${extension} != "tar" && ${extension} != "gz" && ${extension} != "bz2" && ${extension} != "xz" ]]
        then
            echo "${filename}"
            return 0
        else
            filename="${filename%.*}"
            extension="${filename##*.}"
        fi
    done
}

# get unpacked directory name not the full path, the installation will need these
mysql_directory=`get_unpacked_name ${mysql_pkg_name}`
php_directory=`get_unpacked_name ${php_pkg_name}`
redis_directory=`get_unpacked_name ${redis_pkg_name}`
nginx_directory=`get_unpacked_name ${nginx_pkg_name}`

if [[ ! -d ${save_path} ]]
then
    printf "The directory ${save_path} doesn't exist, now create it.\n"
    mkdir ${save_path}
    printf "${save_path} created.\n"
else
    printf "Begin to check installation packages if exist...\n";
    printf "If packages doesn't exist, it will be download from the internet.\n"
fi

# mysql
if [[ ! -f ${mysql_path} ]]
then
    printf "${mysql_path} doesn't exist, begin to download....\n"
    wget -O ${mysql_path} ${mysql_pkg_url}
fi

# php
if [[ ! -f ${php_path} ]]
then
    printf "${php_path} doesn't exist, begin to download...\n"
    wget -O ${php_path} ${php_pkg_url}
fi

# nginx
if [[ ! -f ${nginx_path} ]]
then
    printf "${nginx_path} doesn't exist, begin to download...\n"
    wget -O ${nginx_path} ${nginx_pkg_url}
fi

# redis
if [[ ! -f ${redis_path} ]]
then
    printf "${redis_path} doesn't exist, begin to download...\n"
    wget -O ${redis_path} ${redis_pkg_url}
fi

# judge whether all the files are downloaded succeed
# mysql
if [[ ! -f ${mysql_path} ]]
then
    printf "Download ${mysql_pkg_name} failed! please check if the given url is valid or check if the save path is valid."
    exit 1
fi

# php
if [[ ! -f ${php_path} ]]
then
    printf "Download ${php_pkg_name} failed! please check if the given url is valid or check if the save path is valid."
    exit 1
fi

# nginx
if [[ ! -f ${nginx_path} ]]
then
    printf "Download ${nginx_pkg_name} failed! please check if the given url is valid or check if the save path is valid."
    exit 1
fi

# redis
if [[ ! -f ${redis_path} ]]
then
    printf "Download ${redis_pkg_name} failed! please check if the given url is valid or check if the save path is valid."
    exit 1
fi

########################################################################################################################
# install nginx
# cd ${save_path}

tar -xvf ${nginx_path} -C ${save_path}
# using absolute path instead enter the corresponding directory
nginx_work_directory=${save_path}/${nginx_directory}
${nginx_work_directory}/configure --with-http_stub_status_module
make -C ${nginx_work_directory}
make install -C ${nginx_work_directory}

# add bin to PATH
ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/
if [[ ! -s /usr/local/bin/nginx ]]; then
    add_env /usr/local/nginx/bin
fi

# nginx configuration
vhost_dir=/usr/local/nginx/conf/vhost
if [[ ! -d ${vhost_dir} ]]
then
    mkdir ${vhost_dir}
fi
# add vhost example
cp ${shell_script_path}/nginx/vhost/vhost-default.conf.example /usr/local/nginx/vhost
rewrite_dir=/usr/local/nginx/conf/rewrite
if [[ ! -d ${rewrite_dir} ]]
then
    mkdir ${rewrite_dir}
fi
cp ${shell_script_path}/nginx/rewrite/laravel.conf /usr/local/nginx/rewrite

# add nginx service
cp ${shell_script_path}/systemd/nginx.service ${service_path}
if [[ -f ${shell_script_path}/systemd/nginx.service ]]; then
    systemctl enable nginx
    systemctl start nginx
else
    message="${shell_script_path}/systemd/nginx.service doesn't exist! We can not start the nginx's system service.\n"
    printf message
    printf message >> ${install_log}
fi

# cd ${shell_script_path}
########################################################################################################################