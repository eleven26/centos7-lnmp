#!/usr/bin/env bash

set -x

# todo write configuration in the beginning
# todo write php configuration option in the beginning

########################################################################################################################
# base dependency package
# yum -y install net-tools wget vim gcc git autoconf bzip2

# mysql dependency package
# yum -y install libaio

# nginx dependency package
# yum -y install pcre-devel zlib-devel

# php dependency package
#yum -y install libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel freetype-devel openldap-devel
#libmcrypt

yum -y install net-tools wget vim gcc git autoconf bzip2 libaio pcre-devel make \
    zlib-devel libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel freetype-devel openldap-devel

centos_version=$(hostnamectl | grep "Operating System" | awk '{print $5}')
if [[ ${centos_version} -ne 7 ]]
then
    yum -y install libmcrypt-devel
else
    # yum -y install libmcrypt-devel # doesn't work in centos7
    # centos7 php openssl dependency package
    yum -y install epel-release
    yum -y install libmcrypt-devel.x86_64
fi
########################################################################################################################

# NLS nuisances.
export LC_ALL=C
export LANGUAGE=C

source config.sh
install_log=install.log
touch ${install_log}

if [[ ! -d ${save_path} ]]
then
    printf "The directory %s doesn't exist, now create it.\n" "${save_path}"
    mkdir ${save_path}
    printf "%s created.\n" "${save_path}"
else
    printf "Begin to check installation packages if exist...\n";
    printf "If packages doesn't exist, it will be download from the internet.\n"
fi

# mysql
if [[ ! -f ${save_path}/${mysql_pkg_name} ]]
then
    printf "%s doesn't exist, begin to download....\n" "${save_path}/${mysql_pkg_name}"
    wget -O ${save_path}/${mysql_pkg_name} ${mysql_pkg_url}
fi

# php
if [[ ! -f ${save_path}/${php_pkg_name} ]]
then
    printf "%s doesn't exist, begin to download...\n" "${save_path}/${php_pkg_name}"
    wget -O ${save_path}/${php_pkg_name} ${php_pkg_url}
fi

# redis
if [[ ! -f ${save_path}/${redis_pkg_name} ]]
then
    printf "%s doesn't exist, begin to download...\n" "${save_path}/${redis_pkg_name}"
    wget -O ${save_path}/${redis_pkg_name} ${redis_pkg_url}
fi

# nginx
if [[ ! -f ${save_path}/${nginx_pkg_name} ]]
then
    printf "%s doesn't exist, begin to download...\n" "${save_path}/${nginx_pkg_name}"
    wget -O ${save_path}/${nginx_pkg_name} ${nginx_pkg_url}
fi

# phpredis
if [[ ! -d ${phpredis_directory} ]]
then
    git clone ${phpredis_pkg_url} ${phpredis_directory}
fi

# judge whether all the files are downloaded succeed
# mysql
if [[ ! -f ${save_path}/${mysql_pkg_name} ]]
then
    printf "Download %s failed! please check if the given url is valid or check if the save path is valid." "${mysql_pkg_name}"
    exit 1
fi

# php
if [[ ! -f ${save_path}/${php_pkg_name} ]]
then
    printf "Download %s failed! please check if the given url is valid or check if the save path is valid." "${php_pkg_name}"
    exit 1
fi

# nginx
if [[ ! -f ${save_path}/${nginx_pkg_name} ]]
then
    printf "Download %s failed! please check if the given url is valid or check if the save path is valid." "${nginx_pkg_name}"
    exit 1
fi

# redis
if [[ ! -f ${save_path}/${redis_pkg_name} ]]
then
    printf "Download %s failed! please check if the given url is valid or check if the save path is valid." "${redis_pkg_name}"
    exit 1
fi

# phpredis
if [[ ! -d ${phpredis_directory} ]]
then
    printf "Download %s failed! please check if the given url is valid or check if the save path is valid." "${phpredis_directory}"
    exit 1
fi

########################################################################################################################
# install mysql
# cd ${save_path}
# use the absolute path instead of enter the save path
if [[ ! -d ${mysql_install_dir} ]]
then
    printf "Decompressing %s to %s....\n" "${save_path}/${mysql_pkg_name}" "${save_path}"
    if [[ ! -f "${save_path}/${mysql_pkg_name}.gz" ]]; then
        tar -xvf ${save_path}/${mysql_pkg_name} -C ${save_path}
    fi

    printf "Decompressing %s/%s.gz to /usr/local\n" "${save_path}" "${mysql_pkg_name}"
    tar -xvf "${save_path}/${mysql_pkg_name}.gz" -C /usr/local

    printf "Creating mysql soft link.\n"
    if [[ -d "/usr/local/${mysql_directory}" ]]; then
        ln -s "/usr/local/${mysql_directory}" /usr/local/mysql
    fi

    soft_link_dir=$(readlink -f /usr/local/mysql)
    #todo readlink -f /usr/local/mysql == /usr/local/mysql_directory}
    if [[ ! ${soft_link_dir} == "/usr/local/mysql/{$mysql_directory}" ]]; then
        printf "Create mysql soft link failed!\n"
    fi

    printf "Adding mysql lib to /etc/ld.so.conf.\n"
    grep "/usr/local/mysql/lib" /etc/ld.so.conf || printf "\n/usr/local/mysql/lib\n" >> /etc/ld.so.conf
    ldconfig -v

    if [[ ! -d /usr/local/${mysql_directory} ]]
    then
        printf "/usr/local/%s doesn't exist.\n" "${mysql_directory}"
        printf "Decompression %s failed! Installation was interrupted.\n" "${mysql_pkg_name}"
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

    if [[ -f ${current_path}/mysql/my.cnf ]]; then
        printf "Copy mysql configuration file to /etc...\n"
        cp "${current_path}/mysql/my.cnf" /etc
    else
        message="${current_path}/mysql/mysql.cnf doesn't exist!\n"
        printf message
        printf message >> ${install_log}
    fi

    if [[ -f ${current_path}/systemd/mysql.service ]]; then
        printf "Copy mysql service file to %s, so that mysql can run as a system's service...\n" "${service_path}"
        cp "${current_path}/systemd/mysql.service" ${service_path}
    else
        message="${current_path}/systemd/mysql.service doesn't exist!\n"
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

    # add mysql bin to environment
    printf "\n"
    add_env /usr/local/mysql/bin
    # shellcheck source=/dev/null
    source ${profile_file}

    if [[ -f ${current_path}/systemd/mysql.service ]]; then
        systemctl enable mysql
        systemctl start mysql
    else
        message="File ${current_path}/systemd/mysql.service doesn't exist! We can not start the mysql service, you can add it manually."
        printf message
    fi
fi
#todo modify mysql root password using mysql script, before do that ensure mysqld service is started.

# cd ${current_path}
########################################################################################################################


#########################################################################################################################
# install nginx
# cd ${save_path}
if [[ ! -d ${nginx_install_dir} ]]
then
    tar -xvf ${save_path}/${nginx_pkg_name} -C ${save_path}
    # using absolute path instead enter the corresponding directory
    # we cannot use absolute path because nginx's configure file contains relative path
    nginx_work_directory=${save_path}/${nginx_directory}

    printf "Exit script if %s doesn't exist." "${nginx_work_directory}"
    cd "${nginx_work_directory}" || exit 1
    ./configure --with-http_stub_status_module
    make
    make install

    # add bin to PATH
    ln -s /usr/local/nginx/sbin/nginx /usr/local/bin/
    if [[ ! -s /usr/local/bin/nginx ]]; then
        add_env /usr/local/nginx/bin
        # shellcheck source=/dev/null
        source ${profile_file}
    fi

    # nginx configuration
    vhost_dir=/usr/local/nginx/conf/vhost
    if [[ ! -d ${vhost_dir} ]]
    then
        mkdir ${vhost_dir}
    fi
    # add vhost example
    cp "${current_path}/nginx/vhost/vhost-default.conf.example" /usr/local/nginx/vhost
    rewrite_dir=/usr/local/nginx/conf/rewrite
    if [[ ! -d ${rewrite_dir} ]]
    then
        mkdir ${rewrite_dir}
    fi
    cp "${current_path}/nginx/rewrite/laravel.conf" /usr/local/nginx/rewrite

    # add nginx service
    cp "${current_path}/systemd/nginx.service" ${service_path}
    if [[ -f ${current_path}/systemd/nginx.service ]]; then
        systemctl enable nginx
        systemctl start nginx
    else
        message="${current_path}/systemd/nginx.service doesn't exist! We can not start the nginx's system service.\n"
        printf message
        printf message >> ${install_log}
    fi
fi

printf "Exit the script if %s doesn't exist.\n" "${current_path}"
cd "${current_path}" || exit 1
########################################################################################################################


########################################################################################################################
# install php, it will take a long time
if [[ ! -d ${php_install_dir} ]]
then
    tar -xvf ${save_path}/${php_pkg_name} -C ${save_path}
    libxml2_lib=/usr/include/libxml2/libxml # fix off_t type error
    if [[ -d ${libxml2_lib} ]]
    then
        grep "${libxml2_lib}" /etc/ld.so.conf || printf "\n%s\n" "${libxml2_lib}" >> /etc/ld.so.conf
    fi
    ldconfig -v

    php_work_directory=${save_path}/${php_directory}
    # configure
    printf "Exit the script if directory %s doesn't exist.\n" "${php_work_directory}"
    cd "${php_work_directory}" || exit 4
    ./configure ${php_configure_option}
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
    # shellcheck source=/dev/null
    source ${profile_file}

    # add user www and group www
    groupadd www
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
        printf "%s" "${message}"
    else
        printf "Now modify www.conf to change user and group from nobody to www...\n"
        sed -i "s/user = nobody/user = www/g" /usr/local/php/etc/php-fpm.d/www.conf
        sed -i "s/group = nobody/group = www/g" /usr/local/php/etc/php-fpm.d/www.conf
    fi

    # add php-fpm service
    cp "${current_path}/systemd/php-fpm.service" ${service_path}
    if [[ ! -f ${current_path}/systemd/php-fpm.service ]]; then
        printf "%s/systemd/php-fpm.service doesn't exist.\n We can not start php-fpm service!\n" "${current_path}"
    else
        systemctl enable php-fpm
        systemctl start php-fpm
    fi
fi

printf "Exit the script if %s doesn't exist.\n" "${current_path}"
cd "${current_path}" || exit 1
########################################################################################################################


########################################################################################################################
# install redis
# cd ${save_path}
if [[ ! -d ${redis_install_dir} ]]
then
    tar -xvf ${save_path}/${redis_pkg_name} -C ${save_path}
    redis_work_directory=${save_path}/${redis_directory}

    printf "Exit the script if directory %s doesn't exist.\n" "${redis_work_directory}"
    cd "${redis_work_directory}" || exit 1
    make
    make PREFIX=${redis_install_dir} install

    if [[ -f ${redis_work_directory}/redis.conf ]]; then
        cp "${redis_work_directory}/redis.conf" /etc
    else
        printf "Redis configuration file doesn't exist. please add it manually!\n"
    fi
    if [[ -f /etc/redis.conf ]]; then
        sed -i "s/daemonize no/daemonize yes/g" /etc/redis.conf
    else
        printf "/etc/redis.conf doesn't exist! Redis installation may be failed. \n"
        exit 1
    fi

    # add redis service
    cp "${current_path}/systemd/redis.service" ${service_path}
    if [[ -f ${service_path}/redis.service ]]; then
        systemctl enable redis
        systemctl start redis
    fi
fi

# install php redis extension if needed
php_extension_dir=$(${php_install_dir}/bin/php-config | grep extension-dir | awk '{print $NF}' | sed -e 's/\[//' | sed -e 's/\]//')
redis_wc=$(ls "${php_extension_dir}" | grep -c redis.so)
if [[ ! ${redis_wc} -gt 0 ]]
then
    printf "Exit the script if phpredis can not downloaded succeefully.\n"
    cd "${phpredis_directory}" || exit 1
    git checkout -b php7 origin/php7
    phpize
    ./configure --with-php-config=php-config
    make && make install

    # modify php.ini add redis.so
    if [[ -f /usr/local/php/etc/php.ini ]]; then
        printf "Finishes install redis extension, now modify php.ini to add redis.so to extension. \n"
        sed -i "s/;extension=php_shmop.dll/;extension=php_shmop.dll\nextension=redis.so/g" /usr/local/php/etc/php.ini
    fi
    systemctl restart php-fpm
fi
# shellcheck source=/dev/null
source ${profile_file}
cd "${current_path}" || exit 1

########################################################################################################################