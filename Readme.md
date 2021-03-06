### 这个就很好用了，https://lnmp.org/ ,下面这个适用场景太窄了

CentOS 7 - lnmp
===

[![Project Status](http://opensource.box.com/badges/active.svg)](http://opensource.box.com/badges)
[![Project Status](http://opensource.box.com/badges/maintenance.svg)](http://opensource.box.com/badges)

CentOS 7 - lnmp is a shell script to install MySQL, php, nginx and redis in CentOS 7, and set up system service. Pass test in CentOS 7 minimal installation.

The default version of each software are listed below:

  - php 7.0.11
  - MySQL 5.7.15
  - nginx 1.11.4
  - Redis 3.2.3

All these software will be install in /usr/local directory by default.

Installation
--

Install the base dependency.

```
yum -y install net-tools git
```

Clone this repository to /root/downloads.
```
git clone https://github.com/eleven26/centos7-lnmp.git
```
Enter the repository directory. The packages will be save at  /path/to/centos7-lnmp/downloads.
```
cd centos7-lnmp
```
Checkout branch to tag v1.2-stable, master or master-dev is in development.
```
git checkout v1.2-stable
```
Change the installation script mode so that we can run it.
```
chmod +x install.sh
```
Run this script to begin installation.
```
./install.sh
```

Clean installation after failing to install some packages
--
```
chmod +x clean.sh
```
And then run
```
./clean.sh --help
```
to see what can you do.
For example, you can remove php use 
```
./clean.sh --php
``` 

Check if installation is succeed
--
It will take a long time to do these job. After finish installation, you can run these command to check whether if all installation is succeed.
```
systemctl status mysql
systemctl status nginx
systemctl status php-fpm
systemctl status redis
```
>If all these services' status are running, it mean that you have successfully install.
>If there is any service is not running, check whether if the services' file exists or if >configuration's syntax is allright. Otherwise, check mysql or www user and group if exist.


Feedback
--
CentOS 7-lnmp work fine in my machine. It may be some problem when use it in different machine or try to use it in different linux distributions. If you have any problem using this script, you can 

* [Add an issue](https://github.com/eleven26/centos7-lnmp/issues) at github.
