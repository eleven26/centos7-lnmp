current_path=$(pwd)
profile_file=/etc/profile
service_path=/lib/systemd/system

save_path=${current_path}/downloads

# packages download's url
mysql_pkg_url=http://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.15-linux-glibc2.5-x86_64.tar
php_pkg_url=http://cn2.php.net/get/php-7.0.11.tar.bz2/from/this/mirror
redis_pkg_url=http://download.redis.io/redis-stable.tar.gz
nginx_pkg_url=http://nginx.org/download/nginx-1.11.4.tar.gz
phpredis_pkg_url=https://github.com/phpredis/phpredis.git

# get file name with file extension
mysql_pkg_name=$(echo ${mysql_pkg_url} | awk -F '/' '{print $NF}')
php_pkg_name=$(echo ${php_pkg_url} | awk -F '/' '{print $5}')
redis_pkg_name=$(echo ${redis_pkg_url} | awk -F '/' '{print $NF}')
nginx_pkg_name=$(echo ${nginx_pkg_url} | awk -F '/' '{print $NF}')

php_configure_option=$(cat << EOF
--prefix=/usr/local/php \
--with-config-file-path=/usr/local/php/etc \
--with-mysqli=/usr/local/mysql/bin/mysql_config \
--with-iconv \
--with-freetype-dir \
--with-jpeg-dir \
--with-png-dir \
--with-zlib \
--with-libxml-dir \
--enable-xml \
--disable-rpath \
--enable-safe-mode \
--enable-shmop \
--enable-sysvsem \
--enable-inline-optimization \
--with-curl \
--enable-mbregex \
--enable-fpm \
--enable-mbstring \
--with-mcrypt \
--with-gd \
--enable-gd-native-ttf \
--with-openssl \
--with-mhash \
--enable-pcntl \
--enable-sockets \
--with-xmlrpc \
--enable-zip \
--enable-soap \
--without-pear \
--with-zlib \
--enable-pdo \
--with-pdo-mysql \
--enable-opcache
EOF
)

# add some environment variable
function add_env() {
    printf "\nexport PATH=%s:\$PATH\n" "$1" >> ${profile_file}
    return 0
}

# get the correct directory name after unpacked
function get_unpacked_name(){
    local filename=$1
    local extension="${filename##*.}"
    while true
    do
        if [[ ${extension} != "tar" && ${extension} != "gz" && ${extension} != "bz2" && ${extension} != "xz" ]]
        then
            echo "${filename}"
            return 0
        else
            # http://pubs.opengroup.org/onlinepubs/9699919799.2016edition/utilities/V3_chap02.html#tag_18_06_02
            # Remove Smallest Suffix Pattern
            filename="${filename%.*}"
            # Remove Largest Prefix Pattern (greedy match)
            extension="${filename##*.}"
        fi
    done
}

# get unpacked directory name not the full path, the installation will need these
mysql_directory=$(get_unpacked_name "${mysql_pkg_name}")
php_directory=$(get_unpacked_name "${php_pkg_name}")
redis_directory=$(get_unpacked_name "${redis_pkg_name}")
nginx_directory=$(get_unpacked_name "${nginx_pkg_name}")
phpredis_directory="${save_path}/phpredis"

mysql_install_dir=/usr/local/mysql
php_install_dir=/usr/local/php
redis_install_dir=/usr/local/redis
nginx_install_dir=/usr/local/nginx