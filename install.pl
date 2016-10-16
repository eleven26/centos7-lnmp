#!/usr/bin/perl
use 5.010;
use strict;
use warnings FATAL => 'all';

use File::Spec;
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
my $install_dir = '/usr/local';          # install directory

my $save_path = $current_path.'/download'; # downloaded file will be save in download in current directory instead at /root/download

my %download_url = (
    mysql    => 'http://dev.mysql.com/get/Downloads/MySQL-5.7/mysql-5.7.15-linux-glibc2.5-x86_64.tar',
    php      => 'http://cn2.php.net/get/php-7.0.11.tar.bz2/from/this/mirror',
    redis    => 'http://download.redis.io/redis-stable.tar.gz',
    nginx    => 'http://nginx.org/download/nginx-1.11.4.tar.gz',
    phpredis => 'https://github.com/phpredis/phpredis.git',
);
my %save_name = (
    mysql    => &get_package_name($download_url{'mysql'}),
    php      => &get_package_name($download_url{'php'}),
    redis    => &get_package_name($download_url{'redis'}),
    nginx    => &get_package_name($download_url{'nginx'}),
    phpredis => 'phpredis',
);
my %package_path = (
    mysql    => $save_path.$save_name{'mysql'},
    php      => $save_path.$save_name{'php'},
    redis    => $save_path.$save_name{'redis'},
    nginx    => $save_path.$save_name{'nginx'},
    phpredis => $save_path.$save_name{'phpredis'},
);
my %package_name = (
    mysql    => basename($download_url{'mysql'}),
    php      => `echo $download_url{''} | awk -F '/' '{print \$(NF -3)}'`,
    redis    => basename($download_url{'redis'}),
    nginx    => basename($download_url{'nginx'}),
);
my %package_dir = (
    mysql    => &get_unpacked_name($save_name{'mysql'}),
    php      => &get_unpacked_name($save_name{'php'}),
    redis    => &get_unpacked_name($save_name{'redis'}),
    nginx    => &get_unpacked_name($save_name{'nginx'}),
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

# add some environment variable
sub add_env {
    my $bin_path = $_[0];
    open PROFILE, '>>', $profile_file;
    say PROFILE "\nexport PATH=$bin_path:\$PATH\n";
}

# get folder name after uncompress package, remove extension like bz2, tar...
sub get_unpacked_name {
    my $package_name = $_[0];
    if ($package_name =~ /\/((.*?)\.(tar|gz|bz2|xz))/)
    {
        if ($2 =~ /((.*?)\.(tar|gz|bz2|xz))/) {
            $2;
        }
        $2;
    }
}

sub get_package_name {
    my $url = $_[0];
    if ($url =~ /\/(.*?\.(tar|gz|bz2|xz))/)
    {
        $1;
    }
}

say "check $save_path if exists.";
system "mkdir $save_path" if !-d $save_path;

system "wget -O $package_path{'mysql'} $download_url{'mysql'}" if !-f $package_path{'mysql'};
system "wget -O $package_path{'php'}   $download_url{'php'}" if !-f $package_path{'php'};
system "wget -O $package_path{'redis'} $download_url{'redis'}" if !-f $package_path{'redis'};
system "wget -O $package_path{'nginx'} $download_url{'nginx'}" if !-f $package_path{'nginx'};

# git clone phpredis
warn "Please ensure git clone successfully.";
system "git clone $download_url{'phpredis'} $package_path{'phpredis'}" if !-d $package_path{'phpredis'};

say "The script will exit if download has been failed.";
die "Download package fails." if (
           (!-f $package_path{'mysql'}    && say "Download $save_name{'mysql'} fails.")
        || (!-f $package_path{'php'}      && say "Download $save_name{'php'} fails.")
        || (!-f $package_path{'redis'}    && say "Download $save_name{'nginx'} fails.")
        || (!-f $package_path{'nginx'}    && say "Download $save_name{'nginx'} fails.")
        || (!-d $package_path{'phpredis'} && say "Download $save_name{'phpredis'} fails.")
);

# install mysql first
unless (-d $install_dir.'/mysql')
{
    say "Decompress $package_path{'mysql'} to $save_path";
    system "tar -xvf $package_path{'mysql'} -C $save_path" unless -f "$package_path{'mysql'}.gz";
    system "tar -xvf $package_path{'mysql'}.gz -C $install_dir";

    say "Create mysql soft link.";
    symlink "$install_dir/$package_dir{'mysql'} $install_dir/mysql"
        unless (-l "$install_dir/mysql" && ("$install_dir/$package_dir{'mysql'}" eq (readlink "$install_dir/mysql")));

    say "Adding mysql lib to /etc/ld.so.conf.";
    system "grep '$install_dir/mysql/lib' /etc/ld.so.conf || echo $install_dir/mysql/lib >> /etc/ld.so.conf";
    system "ldconfig -v";

    system "mkdir $install_dir/mysql/data" unless -d $install_dir.'/mysql/data';

    say "Copy mysql configuration file to /etc.";
    system "cp '${current_path}/mysql/my.cnf' /etc" or warn "can not copy mysql configuration file: $!.";

    say "Copy mysql service file to $service_path, so that mysql can run as a system's service.";
    system "cp '${current_path}/systemd/mysql.service' ${service_path}";

    # initialize mysql
    say "Now initializing mysql, after this finishes, it will generate the initializing password for root";
    # add user and group
    say "Adding user mysql and group mysql.";
    system "groupadd mysql" or warn "can not add mysql group: $!";
    system "useradd -r -g mysql -s /bin/false mysql" or warn "can not add use mysql: $!";
    say "Changing mysql directory owned by mysql.";
    system "chown -R mysql:mysql $install_dir/mysql" or warn "$install_dir/mysql can not be chown: $!";

    # attention: the next line will generate output in ~/mysql_initialize, the root's password will be appeared in that file
    say "Begin to initializing mysql.";
    system "$install_dir/mysql/bin/mysqld --initialize --user=mysql > ~/mysql_initialize 2>&1";
    # tail -1 ~/mysql_initialize | awk '{print $NF}'

    &add_env("/usr/local/mysql/bin");
    system "source $profile_file";

    if (-f $service_path.'/mysql.service') {
        system "systemctl enable mysql";
        system "systemctl start mysql";
    } else {
        warn "$profile_file/mysql.service doesn't exist.";
    }
}















