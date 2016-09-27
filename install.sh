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
nginx_directory=`get_unpacked_name ${redis_pkg_name}`

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
# install mysql
# cd ${save_path}
# use the absolute path instead of enter the save path
printf "Decompressing ${mysql_path} to ${save_path}....\n"
tar -xvf ${mysql_path} -C ${save_path}

printf "Decompressing ${save_path}/${mysql_pkg_name}.gz to /usr/local\n"
tar -xvf "${save_path}/${mysql_pkg_name}.gz" -C /usr/local

printf "Creating mysql soft link.\n"
ln -s "/usr/local/${mysql_directory}" /usr/local/mysql

printf "Adding mysql lib to /etc/ld.so.conf.\n"
cat /etc/ld.so.conf | grep "/usr/local/mysql/lib" || printf "\n/usr/local/mysql/lib\n" >> /etc/ld.so.conf
ldconfig -v

if [[ ! -d /usr/local/${mysql_directory} ]]
then
    printf "/usr/local/${mysql_directory} doesn't exist.\n"
    printf "Decompression ${mysql_pkg_name} failed! Installation was interrupted.\n"
    exit 2
fi

if [[ ! -s /usr/local/mysql ]]
then
    printf "Create soft link /usr/local/mysql failed! Installation was interrupted, you can create the soft link manually.\n"
    exit 2
fi

# mysql configuration
if [[ ! -d /usr/local/mysql/data ]]; then
    printf "Mysql data directory doesn't exist. Creating directory /usr/local/mysql/data....\n"
    mkdir /usr/local/mysql/data
fi

if [[ -f ${shell_script_path}/mysql/my.cnf ]]; then
    printf "Copy mysql configuration file to /etc...\n"
    cp ${shell_script_path}/mysql/my.cnf /etc
else
    message="${shell_script_path}/mysql/mysql.cnf doesn't exist!\n"
    printf message
    printf message >> ${install_log}
fi

if [[ -f ${shell_script_path}/systemd/mysql.service ]]; then
    printf "Copy mysql service file to ${service_path}, so that mysql can run as a system's service...\n"
    cp ${shell_script_path}/systemd/mysql.service ${service_path}
else
    message="${shell_script_path}/systemd/mysql.service doesn't exist!\n"
    printf message
    printf message >> ${install_log}
fi

# initialize mysql
printf "Now initializing mysql, after this finishes, it will generate the initializing password for root\n"
# add user and group
printf "Adding user mysql and group mysql...\n"
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
printf "Changing mysql directory owned by mysql...\n"
chown -R mysql:mysql /usr/local/mysql

# attention: the next line will generate output in ~/mysql_initialize, the root's password will be appeared in that file
printf "Begin to initializing mysql....\n"
/usr/local/mysql/bin/mysqld --initialize --user=mysql > ~/mysql_initialize 2>&1
# tail -1 ~/mysql_initialize | awk '{print $NF}'
root_pass=$(`tail -1 ~/mysql_initialize | awk '{print $NF}'`)

# add mysql bin to environment
printf "\n"
add_env /usr/local/mysql/bin

if [[ -f ${shell_script_path}/systemd/mysql.service ]]; then
    systemctl enable mysql
    systemctl start mysql
else
    message="File ${shell_script_path}/systemd/mysql.service doesn't exist! We can not start the mysql service, you can add it manually."
    printf message
fi

printf "Complete mysql installation!\n The initial root password is ${root_pass}"

#todo modify mysql root password using mysql script, before do that ensure mysqld service is started.

# cd ${shell_script_path}
########################################################################################################################


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


########################################################################################################################
# install php, it will take a long time
# cd ${save_path}

tar -xvf ${php_path} -C ${save_path}
libxml2_lib=/usr/include/libxml2/libxml
if [[ -d ${libxml2_lib} ]]
then
    cat /etc/ld.so.conf | grep "${libxml2_lib}" || printf "\n${libxml2_lib}\n" >> /etc/ld.so.conf
fi
ldconfig -v

php_work_directory=${save_path}/${php_directory}
# configure
${php_work_directory}/configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-iconv --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-discard-path --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-fastcgi --enable-fpm --enable-force-cgi-redirect --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-zlib --enable-pdo --with-pdo-mysql --enable-opcache
make -C ${php_work_directory}
make install -C ${php_work_directory}

if [[ ! -d /usr/local/php ]]; then
    printf "Install php failed!"
    exit 1
fi
# php configuration
printf "Configuring php...\n"
cp /path/to/php-source/php.ini-development /usr/local/php/etc/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 50M/g" /usr/local/php/etc/php.ini

# add environment variable
printf "Add php bin to environment varionment."
add_env /usr/local/php/bin:/usr/local/php/sbin

# add user www and group www
grouped www
useradd -r -g www -s /bin/false www

# php-fpm configuration
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf

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
# cd ${shell_script_path}
########################################################################################################################


########################################################################################################################
# install redis
# cd ${save_path}
tar -xvf ${redis_path} -C ${save_path}
redis_work_directory=${save_path}/${redis_directory}
make -C ${redis_work_directory}
make install -C ${redis_work_directory} PREFIX=/usr/local/redis install

add_env /usr/local/redis/bin
if [[ -f ${redis_work_directory}redis.conf ]]; then
    cp ${redis_work_directory}redis.conf /etc
else
    printf "Redis configuration file doesn't exist. please add it manually!\n"
fi
if [[ -f /etc/redis.conf ]]; then
    sed -i "s/daemonize no/daemonize yes/g" /etc/redis.conf
fi

# add redis service
cp ${shell_script_path}/systemd/redis.service ${service_path}


# install php redis extension
git clone https://github.com/phpredis/phpredis.git
cd phpredis
git checkout -b php7 origin/php7
phpize
./configure --with-php-config=php-config
make && make install

# modify php.ini add redis.so
if [[ -f /usr/local/php/etc/php.ini ]]; then
    sed -i "s/;extension=php_shmop.dll/;extension=php_shmop.dll\nextension=redis.so/g" /usr/local/php/etc/php.ini
fi


systemctl restart php-fpm
cd ${shell_script_path}

########################################################################################################################