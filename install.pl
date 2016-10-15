#!/usr/bin/perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use File::Basename;

system 'export LC_ALL=C && export LANGUAGE=C';

# install basic dependency
system 'yum -y install net-tools wget vim gcc git autoconf bzip2 libaio pcre-devel zlib-devel libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel freetype-devel openldap-devel' or die 'can not install basic dependency';

my $centos_version = system "hostnamectl | grep 'Operating System' | awk '{print \$5}'";
if ($centos_version != 7)
{
    system 'yum -y install libmcrypt-devel' or die 'can not install libmcrypt-devel';
} else
{
    # yum -y install libmcrypt-devel # doesn't work in centos7
    # centos7 php openssl dependency package
    system 'yum -y install epel-release libmcrypt-devel.x86_64' or die 'can not install libmcrypt-devel';
}


my $current_path = `pwd`;                # get current path
my $profile_file='/etc/profile';         # bin path will be added to this file
my $service_path='/lib/systemd/system';  # system service configuration file save path

my $save_path = $current_path.'/download'; # downloaded file will be save in download in current directory instead at /root/download

my %save_name = (
    mysql    => 'mysql-5.7.15-linux-glibc2.5-x86_64.tar',
    php      => 'php-7.0.11.tar.bz2',
    redis    => 'redis-stable.tar.gz',
    nginx    => 'nginx-1.11.4.tar.gz',
);
my %download_url = (
    mysql    => 'http://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.15-linux-glibc2.5-x86_64.tar',
    php      => 'http://cn2.php.net/get/php-7.0.11.tar.bz2/from/this/mirror',
    redis    => 'http://download.redis.io/redis-stable.tar.gz',
    nginx    => 'http://nginx.org/download/nginx-1.11.4.tar.gz',
    phpredis => 'https://github.com/phpredis/phpredis.git',
);
my %package_path = (
    mysql    => $save_path.$save_name{'mysql'},
    php      => $save_path.$save_name{'php'},
    redis    => $save_path.$save_name{'redis'},
    nginx    => $save_path.$save_name{'nginx'},
);

my %package_name = (
    mysql    => basename($download_url{'mysql'}),
    php      => `echo $download_url{''} | awk -F '/' '{print \$(NF -3)}'`,
    redis    => basename($download_url{'redis'}),
    nginx    => basename($download_url{'nginx'}),
);

# edit you configuration options here
my $php_configure_option = <<"END";
--prefix=/usr/local/php
--with-config-file-path=/usr/local/php/etc
--with-mysql=/usr/local/mysql
--with-mysqli=/usr/local/mysql/bin/mysql_config
--with-iconv
--with-freetype-dir
--with-jpeg-dir
--with-png-dir
--with-zlib
--with-libxml-dir
--enable-xml
--disable-rpath
--enable-discard-path
--enable-safe-mode
--enable-bcmath
--enable-shmop
--enable-sysvsem
--enable-inline-optimization
--with-curl
--with-curlwrappers
--enable-mbregex
--enable-fastcgi
--enable-fpm
--enable-force-cgi-redirect
--enable-mbstring
--with-mcrypt
--with-gd
--enable-gd-native-ttf
--with-openssl
--with-mhash
--enable-pcntl
--enable-sockets
--with-xmlrpc
--enable-zip
--enable-soap
--without-pear
--with-zlib
--enable-pdo
--with-pdo-mysql
--enable-opcache
END




























