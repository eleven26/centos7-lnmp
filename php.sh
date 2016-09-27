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
# install php, it will take a long time

tar -xvf ${php_path} -C ${save_path}
libxml2_lib=/usr/include/libxml2/libxml
if [[ -d ${libxml2_lib} ]]
then
    cat /etc/ld.so.conf | grep "${libxml2_lib}" || printf "\n${libxml2_lib}\n" >> /etc/ld.so.conf
fi
ldconfig -v

php_work_directory=${save_path}/${php_directory}
# configure
cd ${php_work_directory}
./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-iconv --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-discard-path --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-fastcgi --enable-fpm --enable-force-cgi-redirect --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-zlib --enable-pdo --with-pdo-mysql --enable-opcache
make
make install

if [[ ! -d /usr/local/php ]]; then
    printf "Install php failed!"
    exit 1
fi
# php configuration
printf "Configuring php...\n"
cp ./php.ini-development /usr/local/php/etc/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 50M/g" /usr/local/php/etc/php.ini

# add environment variable
printf "Add php bin to environment varionment."
add_env /usr/local/php/bin:/usr/local/php/sbin

# add user www and group www
grouped www
useradd -r -g www -s /bin/false www

# php-fpm configuration
php_fpm_conf=/usr/local/php/etc/php-fpm.conf.default
fpm_www_conf=/usr/local/php/etc/php-fpm.d/www.conf.default
if [[ ! -f ${php_fpm_conf} || ! -f ${fpm_www_conf} ]]; then
    printf "php-fpm configuration file or php-fpm www.conf file doesn't exist! Php installation maybe failed.\n"
    exit 1
else
    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
fi

if [[ ! -f /usr/local/php/etc/php-fpm.d/www.conf ]]; then
    message="/usr/local/php/etc/php-fpm.d/www.conf doesn't exist! Please configure the php-fpm manually!"
    printf ${message}
else
    printf "Now modify www.conf to change user and group from nobody to www...\n"
    sed -i "s/user = nobody/user = www/g" /usr/local/php/etc/php-fpm.d/www.conf
    sed -i "s/group = nobody/group = www/g" /usr/local/php/etc/php-fpm.d/www.conf
fi

# add php-fpm service
cp ${shell_script_path}/systemd/php-fpm.service ${service_path}
if [[ ! -f ${shell_script_path}/systemd/php-fpm.service ]]; then
    printf "${shell_script_path}/systemd/php-fpm.service doesn't exist.\n We can not start php-fpm service!\n"
else
    systemctl enable php-fpm
    systemctl start php-fpm
fi
cd ${shell_script_path}
########################################################################################################################
