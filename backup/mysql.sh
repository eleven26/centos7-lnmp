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
#todo modify mysql root password using mysql script, before do that ensure mysqld service is started.

# cd ${shell_script_path}
########################################################################################################################
