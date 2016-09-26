#! /bin/sh

# base dependency package
yum -y install net-tools wget vim gcc git autoconf bzip2

# mysql dependency package
yum -y install libaio

# nginx dependency package
yum -y install pcre-devel zlib-devel

# php dependency package
yum -y install libxml2-devel openssl-devel curl-devel libjpeg-devel libpng-devel freetype-devel openldap-devel


centos_version=`hostnamectl | grep "Operating System" | awk '{print $5}'`
if [[ $centos_version -ne 7 ]]
then
    yum -y install libmcrypt-devel
else
    # yum -y install libmcrypt-devel # doesn't work in centos7
    # centos7 php openssl dependency package
    yum -y install epel-release
    yum -y install libmcrypt-devel.x86_64
fi
