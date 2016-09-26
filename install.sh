#! /bin/sh
# NLS nuisances.
LC_ALL=C
export LC_ALL
LANGUAGE=C
export LANGUAGE

shell_script_path=$(pwd)
profile_file=/etc/profile
service_path=/lib/systemc/system

save_path=/root/downloads
package_prefix=/root/downloads

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

# get file name without file extension
mysql_file_name=${mysql_pkg_name%.*}
php_file_name=${php_pkg_name%.*}
redis_file_name=${redis_pkg_name%.*}
nginx_file_name=${nginx_pkg_name%.*}
nginx_file_name=${nginx_file_name%.*}

if [[ ! -d ${save_path} ]]
then
    mkdir ${save_path}
else
    printf "begin to download installation packages.\n";
fi

# mysql
if [[ ! -f ${mysql_path} ]]
then
    printf "${mysql_path} doesn't exist, begin to download.\n"
    wget -O "${save_path}/${mysql_file_name}" ${mysql_pkg_url}
fi

# php
if [[ ! -f ${php_path} ]]
then
    printf "${php_path} doesn't exist, begin to download.\n"
    wget -O "${save_path}/${php_file_name}" ${php_pkg_url}
fi

# nginx
if [[ ! -f ${nginx_path} ]]
then
    printf "${nginx_path} doesn't exist, begin to download.\n"
    wget -O "${save_path}/${nginx_file_name}" ${nginx_pkg_url}
fi

# redis
if [[ ! -f ${redis_path} ]]
then
    printf "${redis_path} doesn't exist, begin to download.\n"
    wget -O "${save_path}/${redis_file_name}" ${redis_pkg_url}
fi

# judge whether all the files are downloaded succeed
# mysql
if [[ ! -f ${mysql_path} ]]
then
    printf "download ${mysql_pkg_name} failed!"
    exit 1
fi

# php
if [[ ! -f ${php_path} ]]
then
    printf "download ${php_pkg_name} failed!"
    exit 1
fi

# nginx
if [[ ! -f ${nginx_path} ]]
then
    printf "download ${nginx_pkg_name} failed!"
    exit 1
fi

# redis
if [[ ! -f ${redis_path} ]]
then
    printf "download ${redis_pkg_name} failed!"
    exit 1
fi

########################################################################################################################
# install mysql
cd ${save_path}

tar -xvf ${mysql_pkg_name}
tar -xvf "${mysql_pkg_name}.gz" -C /usr/local
ln -s "/usr/local/${mysql_file_name}" /usr/local/mysql

printf "\n/usr/local/mysql/lib\n" >> /etc/ld.so.conf
ldconfig -v

# mysql configuration
mkdir /usr/local/mysql/data
cp ${shell_script_path}/mysql/my.cnf /etc
cp ${shell_script_path}/systemd/mysql.service ${service_path}

# initialize mysql
printf "now initializing mysql, after this finish, it will generate the initializing password for root\n"
# add user and group
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
chown -R mysql:mysql /usr/local/mysql

# attention: the next line will generate output in ~/mysql_initialize, the root's password will be appeared in that file
bin/mysqld --initialize --user=mysql > ~/mysql_initialize 2>&1
# tail -1 ~/mysql_initialize | awk '{print $NF}'

# add mysql bin to PATH
printf "\nexport PATH=/usr/local/mysql/bin:\$PATH\n" >> ${profile_file}
source ${profile_file}

systemctl enable mysql
systemctl start mysql
#todo modify mysql root password

cd ${shell_script_path}
########################################################################################################################


########################################################################################################################
# install nginx
cd ${save_path}

tar -xvf ${nginx_pkg_name}
cd ${nginx_file_name}
./configure --with-http_stub_status_module  && make && make install

# add bin to PATH
ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/

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
systemctl enable nginx
systemctl start nginx

cd ${shell_script_path}
########################################################################################################################


########################################################################################################################
# install php, it will take a long time
cd ${save_path}

tar -xvf ${php_pkg_name}
cd ${php_file_name}
libxml2_lib=/usr/include/libxml2/libxml
if [[ -d ${libxml2_lib} ]]
then
    printf "\n${libxml2_lib}\n" >> /etc/ld.so.conf
fi
ldconfig -v

# configure
./configure --prefix=/usr/local/php --with-config-file-path=/usr/local/php/etc --with-mysql=/usr/local/mysql --with-mysqli=/usr/local/mysql/bin/mysql_config --with-iconv --with-freetype-dir --with-jpeg-dir --with-png-dir --with-zlib --with-libxml-dir=/usr --enable-xml --disable-rpath --enable-discard-path --enable-safe-mode --enable-bcmath --enable-shmop --enable-sysvsem --enable-inline-optimization --with-curl --with-curlwrappers --enable-mbregex --enable-fastcgi --enable-fpm --enable-force-cgi-redirect --enable-mbstring --with-mcrypt --with-gd --enable-gd-native-ttf --with-openssl --with-mhash --enable-pcntl --enable-sockets --with-xmlrpc --enable-zip --enable-soap --without-pear --with-zlib --enable-pdo --with-pdo-mysql --enable-opcache
make && make install

# php configuration
cp /path/to/php-source/php.ini-development /usr/local/php/etc/php.ini
sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 50M/g" /usr/local/php/etc/php.ini

# add environment variable
printf "\nexport PATH=/usr/local/php/bin:/usr/local/php/sbin:\$PATH\n" >> ${profile_file}
source ${profile_file}

# add user www and group www
grouped www
useradd -r -g www -s /bin/false www

# php-fpm configuration
cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf

sed -i "s/user = nobody/user = www/g" /usr/local/php/etc/php-fpm.d/www.conf
sed -i "s/group = nobody/group = www/g" /usr/local/php/etc/php-fpm.d/www.conf

# add php-fpm service
cp ${shell_script_path}/systemd/php-fpm.service ${service_path}

cd ${shell_script_path}
########################################################################################################################


########################################################################################################################
# install redis
cd ${save_path}
tar -xvf ${redis_pkg_name}
cd ${redis_file_name}
make
make PREFIX=/usr/local/redis install
printf "\nexport PATH=/usr/local/redis/bin:\$PATH" >> ${profile_file}
source ${profile_file}
cp redis.conf /etc
sed -i "s/daemonize no/daemonize yes/g" /etc/redis.conf

# add redis service
cp ${shell_script_path}/systemd/redis.service ${service_path}

cd ${save_path}

# install php redis extension
git clone https://github.com/phpredis/phpredis.git
cd phpredis
git checkout -b php7 origin/php7
phpize
./configure --with-php-config=php-config
make && make install

# modify php.ini add redis.so
sed -i "s/;extension=php_shmop.dll/;extension=php_shmop.dll\nextension=redis.so/g" /usr/local/php/etc/php.ini
systemctl restart php-fpm

cd ${shell_script_path}

########################################################################################################################