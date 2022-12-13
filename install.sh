#!/bin/bash
###############################################################################
# Flux Telecom - Unindo pessoas e negócios
#
# Copyright (C) 2022 Flux Telecom
# FluxSBC Version 6
# License https://www.gnu.org/licenses/agpl-3.0.html
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################


#################################
##########  variables ###########
#################################

#General Congifuration
TEMP_USER_ANSWER="no"
FLUX_SOURCE_DIR=/opt/flux
FLUX_HOST_DOMAIN_NAME="host.domain.tld"
IS_ENTERPRISE="False"

#FLUX Configuration
FLUXDIR=/var/lib/flux/
FLUXEXECDIR=/usr/local/flux/
FLUXLOGDIR=/var/log/flux/

#Freeswich Configuration
FS_DIR=/usr/share/freeswitch
FS_SOUNDSDIR=${FS_DIR}/sounds/en/us/callie

#HTML and Mysql Configuraition
WWWDIR=/var/www/html
FLUX_DATABASE_NAME="flux"
FLUX_DB_USER="fluxuser"

#################################
####  general functions #########
#################################

#Generate random password
genpasswd() 
{
        length=$1
        digits=({1..9})
        lower=({a..z})
        upper=({A..Z})
        CharArray=(${digits[*]} ${lower[*]} ${upper[*]})
        ArrayLength=${#CharArray[*]}
        password=""
        for i in `seq 1 $length`
        do
                index=$(($RANDOM%$ArrayLength))
                char=${CharArray[$index]}
                password=${password}${char}
        done
        echo $password
}

MYSQL_ROOT_PASSWORD=`echo "$(genpasswd 20)" | sed s/./*/5`
FLUXUSER_MYSQL_PASSWORD=`echo "$(genpasswd 20)" | sed s/./*/5`
#Fetch OS Distribution
get_linux_distribution ()
{
        echo -e "$Cyan ===get_linux_distribution===$Color_Off"
        sleep 2s
        V1=`cat /etc/*release | head -n1 | tail -n1 | cut -c 14- | cut -c1-18`
        V2=`cat /etc/*release | head -n7 | tail -n1 | cut -c 14- | cut -c1-14`
        V3=`cat /etc/*release | grep Deb | head -n1 | tail -n1 | cut -c 14- | cut -c1-19`
        V4=`cat /etc/*release | grep Deb | head -n1 | tail -n1 | cut -c 14- | cut -c1-19`
        if [[ $V1 = "Debian GNU/Linux 9" ]]; then
                DIST="DEBIAN"
                echo -e "$Green ===Your OS is $V1===$Color_Off"
        else if [[ $V2 = "CentOS Linux 7" ]]; then
                DIST="CENTOS"
                echo -e "$Green ===Your OS is $V2===$Color_Off"
        else if [[ $V3 = "Debian GNU/Linux 10" || $V4 = "Debian GNU/Linux 11" ]]; then
                DIST="DEBIAN10"
                echo -e "$Green ===Your OS is $V3===$Color_Off"
        else if [[$V4 = "Debian GNU/Linux 11"]]; then
                echo -e "$Green ===Your OS is $V4===$Color_Off"
        else
                DIST="OTHER"
                echo -e 'Ooops!!! Quick Installation does not support your distribution \nPlease use manual steps or contact FLUX Sales Team \nat sales@flux.com.'
                exit 1
                
                
        fi
        fi
        fi
        fi
        #echo -e "$Green ===Your OS is $DIST===$Color_Off"
        sleep 4s
}


#Verify freeswitch token
verification ()
{
        tput bold
        echo "                       Authentication required !!!!!!
Personal Access Tokens (PAT)s are required to access FreeSWITCH install packages."
        echo ""

        echo "VISIT below link to generate Personal Access Token
https://freeswitch.org/confluence/display/FREESWITCH/HOWTO+Create+a+SignalWire+Personal+Access+Token"
        sleep 3s
        echo "" && echo ""
        read -p "Enter your Personal Access Token: ${FS_TOKEN}"
        tput sgr0
        FS_TOKEN=${REPLY}
        echo ""
        if [ $DIST = "DEBIAN10" ]; then
                wget --http-user=signalwire --http-password=$FS_TOKEN -O /usr/share/keyrings/signalwire-freeswitch-repo.gpg https://freeswitch.signalwire.com/repo/deb/debian-release/signalwire-freeswitch-repo.gpg
                verify_debian10="$?"
                if [ $verify_debian10 = 0 ]; then
                        tput bold
                        echo "******************************************************************************"
                        echo ""
                        echo "You have entered valid token"
                        echo ""
                        echo "******************************************************************************"
                        sleep 4s
                        tput sgr0
                else
                        echo ""
                        tput bold
                        echo "Invalid token"
                        echo "******************************************************************************"
                        echo ""
                        echo "For more information go to https://id.signalwire.com/personal_access_tokens "
                        echo ""
                        echo "******************************************************************************"
                        sleep 3s
                        tput sgr0
                        exit 0
                fi
        elif [ $DIST = "CENTOS" ]; then
                yum -y remove freeswitch-release-repo.noarch
                echo "signalwire" > /etc/yum/vars/signalwireusername
                echo "$FS_TOKEN" > /etc/yum/vars/signalwiretoken
                yum install -y https://$(< /etc/yum/vars/signalwireusername):$(< /etc/yum/vars/signalwiretoken)@freeswitch.signalwire.com/repo/yum/centos-release/freeswitch-release-repo-0-1.noarch.rpm 
                verify_centos="$?"
                if [ $verify_centos = 0 ]; then
                        tput bold
                        echo "******************************************************************************"
                        echo ""
                        echo "You have entered valid token"
                        echo ""
                        echo "******************************************************************************"
                        sleep 4s
                        tput sgr0
                else
                        echo ""
                        tput bold
                        echo "Invalid token"
                        echo "******************************************************************************"
                        echo ""
                        echo "For more information go to https://id.signalwire.com/personal_access_tokens "
                        echo ""
                        echo "******************************************************************************"
                        sleep 3s
                        tput sgr0
                        exit 0
                fi
        fi
}
#Install Prerequisties
install_prerequisties ()
{
        if [ $DIST = "CENTOS" ]; then
                systemctl stop httpd
                systemctl disable httpd
                yum update -y
                yum install -y wget curl git bind-utils ntpdate systemd net-tools whois sendmail sendmail-cf mlocate vim chrony
        else if [ $DIST = "DEBIAN" ]; then
                systemctl stop apache2
                systemctl disable apache2
                apt update
                apt install -y sudo wget curl git dnsutils ntpdate systemd net-tools whois sendmail-bin sensible-mda mlocate vim
        else if [ $DIST = "DEBIAN10" ]; then
                apt-get update
                apt-get install -y sudo wget curl git dnsutils ntpdate systemd net-tools whois sendmail-bin sensible-mda mlocate vim imagemagick chrony
        fi
        fi
        fi
        cd /usr/src/
        wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
        tar -xzvf ioncube_loaders_lin_x86-64.tar.gz
        cd ioncube
}

#Fetch FLUX Source
get_flux_source ()
{
        cd /opt
        git clone https://github.com/fluxtelecom/flux/
	
}

#License Acceptence
license_accept ()
{
        cd /usr/src
        if [ $IS_ENTERPRISE = "True" ]; then
                echo ""
        fi
        if [ $IS_ENTERPRISE = "False" ]; then
                clear
                echo "********************"
                echo "License acceptance"
                echo "********************"
                if [ -f LICENSE ]; then
                        more LICENSE
                else
                        wget --no-check-certificate -q -O GNU-AGPLv5.0.txt https://raw.githubusercontent.com/fluxtelecom/flux/master/LICENSE
                        more GNU-AGPLv5.0.txt
                fi
                echo "***"
                echo "*** I agree to be bound by the terms of the license - [YES/NO]"
                echo "*** " 
                read ACCEPT
                while [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ] && [ "$ACCEPT" != "no" ] && [ "$ACCEPT" != "No" ] && [ "$ACCEPT" != "NO" ]; do
                        echo "I agree to be bound by the terms of the license - [YES/NO]"
                        read ACCEPT
                done
                if [ "$ACCEPT" != "yes" ] && [ "$ACCEPT" != "Yes" ] && [ "$ACCEPT" != "YES" ]; then
                        echo "Ooops!!! License rejected!"
                        LICENSE_VALID=False
                        exit 0
                else
                        echo "Hey!!! Licence accepted!"
                        LICENSE_VALID=True
                fi
        fi
}

#Install PHP
install_php ()
{
        cd /usr/src
        if [ "$DIST" = "DEBIAN" ]; then
                apt -y install lsb-release apt-transport-https ca-certificates 
                echo "deb http://ftp.de.debian.org/debian buster-backports main" | tee /etc/apt/sources.list.d/buster-backports.list
                apt-get update
                apt install -y php7.3 php7.3-fpm php7.3-mysql php7.3-cli php7.3-json php7.3-readline php7.3-xml php7.3-curl php7.3-gd php7.3-json php7.3-mbstring php7.3-mysql php7.3-opcache php7.3-imap
                apt purge php8.1*
                systemctl stop apache2
                systemctl disable apache2
        else if [ "$DIST" = "CENTOS" ]; then
                yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm 
                yum -y install epel-release yum-utils
                yum-config-manager --disable remi-php54
                yum-config-manager --enable remi-php73
                yum install -y php php-fpm php-mysql php-cli php-json php-readline php-xml php-curl php-gd php-json php-mbstring php-opcache php-imap php-pear php-geoip php-imagick libreoffice ghostscript
                systemctl stop httpd
                systemctl disable httpd
        else if [ "$DIST" = "DEBIAN10" ]; then
                apt -y install lsb-release apt-transport-https ca-certificates
                echo "deb http://ftp.de.debian.org/debian buster-backports main" | tee /etc/apt/sources.list.d/buster-backports.list
                apt-get update
                apt install -y php7.3 php7.3-fpm php7.3-mysql php7.3-cli php7.3-json php7.3-readline php7.3-xml php7.3-curl php7.3-gd php7.3-json php7.3-mbstring php7.3-opcache php7.3-imap php7.3-geoip php-pear php-imagick libreoffice ghostscript
                apt purge php8.1*
                systemctl stop apache2
                systemctl disable apache2
        fi
        fi
        fi 
}

#Install Mysql
install_mysql ()
{
        cd /usr/src
        if [ "$DIST" = "DEBIAN" ]; then
                sudo apt install dirmngr --install-recommends
                sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29
                wget https://repo.mysql.com/mysql-apt-config_0.8.22-1_all.deb
                dpkg -i mysql-apt-config_0.8.22-1_all.deb
                apt update
                apt -y install unixodbc unixodbc-bin
                debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}"
                debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}"
                debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"
                DEBIAN_FRONTEND=noninteractive apt -y install mysql-server
                cd /opt/flux/misc/
                tar -xzvf odbc.tar.gz
                cp -rf odbc/libmyodbc8* /usr/lib/x86_64-linux-gnu/odbc/.

        else if [ "$DIST" = "CENTOS" ]; then
                wget https://repo.mysql.com/mysql80-community-release-el7-1.noarch.rpm
                rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
                yum localinstall -y mysql80-community-release-el7-1.noarch.rpm
                yum install -y mysql-community-server unixODBC mysql-connector-odbc
                systemctl start mysqld
                MYSQL_ROOT_TEMP=$(grep 'temporary password' /var/log/mysqld.log | cut -c 14- | cut -c100-111 2>&1)
                mysql -uroot -p${MYSQL_ROOT_TEMP} --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';FLUSH PRIVILEGES;"
        else if [ "$DIST" = "DEBIAN10" ]; then
                apt install gnupg -y
                sudo apt -y install dirmngr --install-recommends
                apt-get install software-properties-common -y
                sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 467B942D3A79BD29
                wget https://repo.mysql.com/mysql-apt-config_0.8.22-1_all.deb
                sudo dpkg -i mysql-apt-config_0.8.22-1_all.deb
                apt update -y
                #apt -y install unixodbc unixodbc-bin
		        apt-get -y install unixodbc unixodbc-dev
                debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${MYSQL_ROOT_PASSWORD}"
                debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${MYSQL_ROOT_PASSWORD}"
                debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"
                DEBIAN_FRONTEND=noninteractive apt -y install mysql-server
                cd /opt/flux/misc/
                tar -xzvf odbc.tar.gz
		        mkdir -p /usr/lib/x86_64-linux-gnu/odbc/.
                cp -rf odbc/libmyodbc8* /usr/lib/x86_64-linux-gnu/odbc/.
	
        fi
        fi
	fi
        echo ""
        echo "MySQL password set to '${MYSQL_ROOT_PASSWORD}'. Remember to delete ~/.mysql_passwd" >> ~/.mysql_passwd
        echo "" >>  ~/.mysql_passwd
        echo "MySQL fluxuser password:  ${FLUXUSER_MYSQL_PASSWORD} " >>  ~/.mysql_passwd
        chmod 400 ~/.mysql_passwd	
}

#Normalize mysql installation
normalize_mysql ()
{
        if [ ${DIST} = "DEBIAN" ]; then
                cp ${FLUX_SOURCE_DIR}/misc/odbc_conf/deb_odbc.ini /etc/odbc.ini
                sed -i '33i wait_timeout=600' /etc/mysql/mysql.conf.d/mysqld.cnf
                sed -i '33i interactive_timeout = 600' /etc/mysql/mysql.conf.d/mysqld.cnf
                sed -i '33i sql_mode=""' /etc/mysql/mysql.conf.d/mysqld.cnf
                systemctl restart mysql
                systemctl enable mysql
        elif  [ ${DIST} = "CENTOS" ]; then
                systemctl start mysqld
                systemctl enable mysqld
                cp ${FLUX_SOURCE_DIR}/misc/odbc_conf/cent_odbc.ini /etc/odbc.ini
                sed -i '26i wait_timeout=600' /etc/my.cnf
                sed -i '26i interactive_timeout = 600' /etc/my.cnf
                sed -i '26i sql-mode=""' /etc/my.cnf
                systemctl restart mysqld
                systemctl enable mysqld
        elif  [ ${DIST} = "DEBIAN10" ]; then
                cp ${FLUX_SOURCE_DIR}/misc/odbc_conf/deb_odbc.ini /etc/odbc.ini
                sed -i '28i wait_timeout=600' /etc/mysql/conf.d/mysql.cnf
                sed -i '28i interactive_timeout = 600' /etc/mysql/conf.d/mysql.cnf
                sed -i '28i sql_mode=""' /etc/mysql/conf.d/mysql.cnf
		sed -i '33i log_bin_trust_function_creators = 1' /etc/mysql/conf.d/mysql.cnf
                sed -i '28i [mysqld]' /etc/mysql/conf.d/mysql.cnf
                systemctl restart mysql
                systemctl enable mysql
        fi
}

#User Response Gathering
get_user_response ()
{
        echo ""
        read -p "Enter FQDN example (i.e ${FLUX_HOST_DOMAIN_NAME}): "
        FLUX_HOST_DOMAIN_NAME=${REPLY}
        echo "Your entered FQDN is : ${FLUX_HOST_DOMAIN_NAME} "
        echo ""
        # read -p "Enter your freeswitch token: ${FS_TOKEN}"
        # FS_TOKEN=${REPLY}
        # echo ""
        read -p "Enter your email address: ${EMAIL}"
        EMAIL=${REPLY}
        echo ""
        read -n 1 -p "Press any key to continue ... "
        NAT1=$(dig +short myip.opendns.com @resolver1.opendns.com)
        NAT2=$(curl http://ip-api.com/json/)
        INTF=$(ifconfig $1|sed -n 2p|awk '{ print $2 }'|awk -F : '{ print $2 }')
        if [ "${NAT1}" != "${INTF}" ]; then
                echo "Server is behind NAT";
                NAT="True"
        fi
        curl --data "email=$EMAIL" --data "data=$NAT2" --data "type=Install" https://fluxbilling.org/lib/
}

#Install FLUX with dependencies
install_flux ()
{
        if [[ ${DIST} = "DEBIAN" || ${DIST} = "DEBIAN10" || ${DIST} = "DEBIAN11" ]]; then
                echo "Installing dependencies for FLUX"
                apt update
                apt install -y nginx ntpdate ntp lua5.1 bc libxml2 libxml2-dev openssl libcurl4-openssl-dev gettext gcc g++
                echo "Installing dependencies for FLUX"
        elif  [ ${DIST} = "CENTOS" ]; then
                echo "Installing dependencies for FLUX"
                yum install -y nginx libxml2 libxml2-devel openssl openssl-devel gettext-devel fileutils gcc-c++
        fi
        echo "Creating neccessary locations and configuration files ..."
        mkdir -p ${FLUXDIR}
        mkdir -p ${FLUXLOGDIR}
        mkdir -p ${FLUXEXECDIR}
        mkdir -p /var/www
        mkdir -p ${WWWDIR}
        cp -rf ${FLUX_SOURCE_DIR}/config/flux-config.conf ${FLUXDIR}flux-config.conf
        cp -rf ${FLUX_SOURCE_DIR}/config/flux.lua ${FLUXDIR}flux.lua
        ln -s ${FLUX_SOURCE_DIR}/web_interface/flux ${WWWDIR}
        ln -s ${FLUX_SOURCE_DIR}/freeswitch/fs ${WWWDIR}
}

#Normalize flux installation
normalize_flux ()
{
	sudo apt-get install -y locales-all
        mkdir -p /etc/nginx/ssl
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
        if [ ${DIST} = "DEBIAN" ]; then
                /bin/cp /usr/src/ioncube/ioncube_loader_lin_7.3.so /usr/lib/php/20180731/
                sed -i '2i zend_extension ="/usr/lib/php/20180731/ioncube_loader_lin_7.3.so"' /etc/php/7.3/fpm/php.ini
                sed -i '2i zend_extension ="/usr/lib/php/20180731/ioncube_loader_lin_7.3.so"' /etc/php/7.3/cli/php.ini
                cp -rf ${FLUX_SOURCE_DIR}/web_interface/nginx/deb_flux.conf /etc/nginx/conf.d/flux.conf
                systemctl start nginx
                systemctl enable nginx
                systemctl start php7.3-fpm
                systemctl enable php7.3-fpm
                chown -Rf root.root ${FLUXDIR}	
                chown -Rf www-data.www-data ${FLUXLOGDIR}
                chown -Rf root.root ${FLUXEXECDIR}
                chown -Rf www-data.www-data ${WWWDIR}/flux
                chown -Rf www-data.www-data ${FLUX_SOURCE_DIR}/web_interface/flux
                chmod -Rf 755 ${WWWDIR}/flux     
                sed -i "s/;request_terminate_timeout = 0/request_terminate_timeout = 300/" /etc/php/7.3/fpm/pool.d/www.conf
                sed -i "s#short_open_tag = Off#short_open_tag = On#g" /etc/php/7.3/fpm/php.ini
                sed -i "s#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=1#g" /etc/php/7.3/fpm/php.ini
                sed -i "s/max_execution_time = 30/max_execution_time = 3000/" /etc/php/7.3/fpm/php.ini
                sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M/" /etc/php/7.3/fpm/php.ini
                sed -i "s/post_max_size = 8M/post_max_size = 20M/" /etc/php/7.3/fpm/php.ini
                sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/7.3/fpm/php.ini
                systemctl restart php7.3-fpm
                CRONPATH='/var/spool/cron/crontabs/flux'
        elif  [ ${DIST} = "CENTOS" ]; then
                cp /usr/src/ioncube/ioncube_loader_lin_7.3.so /usr/lib64/php/modules/
                sed -i '2i zend_extension ="/usr/lib64/php/modules/ioncube_loader_lin_7.3.so"' /etc/php.ini
                cp ${FLUX_SOURCE_DIR}/web_interface/nginx/cent_flux.conf /etc/nginx/conf.d/flux.conf
                setenforce 0
                systemctl start nginx
                systemctl enable nginx
                systemctl start php-fpm
                systemctl enable php-fpm
                chown -Rf root.root ${FLUXDIR}
                chown -Rf apache.apache ${FLUXLOGDIR}
                chown -Rf root.root ${FLUXEXECDIR}
                chown -Rf apache.apache ${WWWDIR}/flux
                chown -Rf apache.apache ${FLUX_SOURCE_DIR}/web_interface/flux
                chmod -Rf 755 ${WWWDIR}/flux
                sed -i "s/;request_terminate_timeout = 0/request_terminate_timeout = 300/" /etc/php-fpm.d/www.conf
                sed -i "s#short_open_tag = Off#short_open_tag = On#g" /etc/php.ini
                sed -i "s#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=1#g" /etc/php.ini
                sed -i "s/max_execution_time = 30/max_execution_time = 3000/" /etc/php.ini
                sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M/" /etc/php.ini
                sed -i "s/post_max_size = 8M/post_max_size = 20M/" /etc/php.ini
                sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php.ini
                systemctl restart php-fpm
                CRONPATH='/var/spool/cron/flux'
        elif  [ ${DIST} = "DEBIAN10" ]; then
		sudo apt-get install -y locales-all
                /bin/cp /usr/src/ioncube/ioncube_loader_lin_7.3.so /usr/lib/php/20180731/
                sed -i '2i zend_extension ="/usr/lib/php/20180731/ioncube_loader_lin_7.3.so"' /etc/php/7.3/fpm/php.ini
                sed -i '2i zend_extension ="/usr/lib/php/20180731/ioncube_loader_lin_7.3.so"' /etc/php/7.3/cli/php.ini
                cp -rf ${FLUX_SOURCE_DIR}/web_interface/nginx/deb_flux.conf /etc/nginx/conf.d/flux.conf
                systemctl start nginx
                systemctl enable nginx
                systemctl start php7.3-fpm
                systemctl enable php7.3-fpm
                chown -Rf root.root ${FLUXDIR}
                chown -Rf www-data.www-data ${FLUXLOGDIR}
                chown -Rf root.root ${FLUXEXECDIR}
                chown -Rf www-data.www-data ${WWWDIR}/flux
                chown -Rf www-data.www-data ${FLUX_SOURCE_DIR}/web_interface/flux
                chmod -Rf 755 ${WWWDIR}/flux
                sed -i "s/;request_terminate_timeout = 0/request_terminate_timeout = 300/" /etc/php/7.3/fpm/pool.d/www.conf
                sed -i "s#short_open_tag = Off#short_open_tag = On#g" /etc/php/7.3/fpm/php.ini
                sed -i "s#;cgi.fix_pathinfo=1#cgi.fix_pathinfo=1#g" /etc/php/7.3/fpm/php.ini
                sed -i "s/max_execution_time = 30/max_execution_time = 3000/" /etc/php/7.3/fpm/php.ini
                sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 20M/" /etc/php/7.3/fpm/php.ini
                sed -i "s/post_max_size = 8M/post_max_size = 20M/" /etc/php/7.3/fpm/php.ini
                sed -i "s/memory_limit = 128M/memory_limit = 512M/" /etc/php/7.3/fpm/php.ini
                systemctl restart php7.3-fpm
                CRONPATH='/var/spool/cron/crontabs/flux'
        fi
                echo "# To call all crons   
                * * * * * cd ${FLUX_SOURCE_DIR}/web_interface/flux/cron/ && php cron.php crons
                " > $CRONPATH
                chmod 600 $CRONPATH
                crontab $CRONPATH
        touch /var/log/flux/flux.log
        touch /var/log/flux/flux_email.log
        chmod -Rf 755 $FLUX_SOURCE_DIR
	    chmod -Rf 777 /opt/flux/
	    chmod -Rf 777 /opt/flux/*
	    chmod -Rf 777 /opt/flux
        chmod 777 /var/log/flux/flux.log
        chmod 777 /var/log/flux/flux_email.log
        sed -i "s#dbpass = <PASSSWORD>#dbpass = ${FLUXUSER_MYSQL_PASSWORD}#g" ${FLUXDIR}flux-config.conf
        sed -i "s#DB_PASSWD=\"<PASSSWORD>\"#DB_PASSWD = \"${FLUXUSER_MYSQL_PASSWORD}\"#g" ${FLUXDIR}flux.lua
        sed -i "s#base_url=https://localhost:443/#base_url=https://${FLUX_HOST_DOMAIN_NAME}/#g" ${FLUXDIR}/flux-config.conf
        sed -i "s#PASSWORD = <PASSWORD>#PASSWORD = ${FLUXUSER_MYSQL_PASSWORD}#g" /etc/odbc.ini
        systemctl restart nginx
}

#Install freeswitch with dependencies
install_freeswitch ()
{

        if [ ${DIST} = "DEBIAN" ]; then
                clear
                echo "Installing FREESWITCH"
                sleep 5
                apt-get install -y gnupg2
                echo "machine freeswitch.signalwire.com login signalwire password $FS_TOKEN" > /etc/apt/auth.conf
                echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
                echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list
                apt-get update -y
                sleep 1s
                apt-get install freeswitch-meta-all -y
                
        elif  [ ${DIST} = "CENTOS" ]; then
                clear
                sleep 5
                echo "Installing FREESWITCH"
                yum install -y epel-release
                yum install -y freeswitch-config-vanilla freeswitch-lang-* freeswitch-sounds-* freeswitch-xml-curl freeswitch-event-json-cdr freeswitch-lua
                apt-get update && apt-get install -y freeswitch-meta-all
                echo "FREESWITCH installed successfully. . ."

        elif  [ ${DIST} = "DEBIAN10" ]; then
                echo "Installing FREESWITCH"
                sleep 6s
                apt-get update && apt-get install -y gnupg2 wget lsb-release
                echo "machine freeswitch.signalwire.com login signalwire password $FS_TOKEN" > /etc/apt/auth.conf
                echo "deb [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" > /etc/apt/sources.list.d/freeswitch.list
                echo "deb-src [signed-by=/usr/share/keyrings/signalwire-freeswitch-repo.gpg] https://freeswitch.signalwire.com/repo/deb/debian-release/ `lsb_release -sc` main" >> /etc/apt/sources.list.d/freeswitch.list
                apt-get update -y
                sleep 2s
                apt-get install freeswitch-meta-all -y
                
        fi
        mv -f ${FS_DIR}/scripts /tmp/.
        ln -s ${FLUX_SOURCE_DIR}/freeswitch/fs ${WWWDIR}
        ln -s ${FLUX_SOURCE_DIR}/freeswitch/scripts ${FS_DIR}
        cp -rf ${FLUX_SOURCE_DIR}/freeswitch/sounds/*.wav ${FS_SOUNDSDIR}/
        cp -rf ${FLUX_SOURCE_DIR}/freeswitch/conf/autoload_configs/* /etc/freeswitch/autoload_configs/
}

#Normalize freeswitch installation
normalize_freeswitch ()
{
        systemctl start freeswitch
        systemctl enable freeswitch
        sed -i "s#max-sessions\" value=\"1000#max-sessions\" value=\"2000#g" /etc/freeswitch/autoload_configs/switch.conf.xml
        sed -i "s#sessions-per-second\" value=\"30#sessions-per-second\" value=\"50#g" /etc/freeswitch/autoload_configs/switch.conf.xml
        sed -i "s#max-db-handles\" value=\"50#max-db-handles\" value=\"500#g" /etc/freeswitch/autoload_configs/switch.conf.xml
        sed -i "s#db-handle-timeout\" value=\"10#db-handle-timeout\" value=\"30#g" /etc/freeswitch/autoload_configs/switch.conf.xml
        rm -rf  /etc/freeswitch/dialplan/*
        touch /etc/freeswitch/dialplan/flux.xml
        rm -rf  /etc/freeswitch/directory/*
        touch /etc/freeswitch/directory/flux.xml
        rm -rf  /etc/freeswitch/sip_profiles/*
        touch /etc/freeswitch/sip_profiles/flux.xml
        chmod -Rf 755 ${FS_SOUNDSDIR}
	chmod -Rf 777 /opt/flux/
        chmod -Rf 777 /usr/share/freeswitch/scripts/flux/lib
	chmod -Rf 777 /var/lib/freeswitch/recordings
	chmod -Rf 777 /var/lib/freeswitch/recordings/*
        if [ ${DIST} = "DEBIAN" ]; then
                cp -rf ${FLUX_SOURCE_DIR}/web_interface/nginx/deb_fs.conf /etc/nginx/conf.d/fs.conf
                chown -Rf root.root ${WWWDIR}/fs
                chmod -Rf 755 ${WWWDIR}/fs
                /bin/systemctl restart freeswitch
                /bin/systemctl enable freeswitch
        elif  [ ${DIST} = "DEBIAN10" ]; then
                cp -rf ${FLUX_SOURCE_DIR}/web_interface/nginx/deb_fs.conf /etc/nginx/conf.d/fs.conf
                chown -Rf root.root ${WWWDIR}/fs
                chmod -Rf 755 ${WWWDIR}/fs
                /bin/systemctl restart freeswitch
                /bin/systemctl enable freeswitch
        elif  [ ${DIST} = "CENTOS" ]; then
                cp ${FLUX_SOURCE_DIR}/web_interface/nginx/cent_fs.conf /etc/nginx/conf.d/fs.conf
                chown -Rf root.root ${WWWDIR}/fs
                chmod -Rf 755 ${WWWDIR}/fs
                sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/sysconfig/selinux
                sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
                /usr/bin/systemctl restart freeswitch
                /usr/bin/systemctl enable freeswitch
        fi
}

#Install Database for FLUX
install_database ()
{
        mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} create ${FLUX_DATABASE_NAME}
        mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "CREATE USER 'fluxuser'@'localhost' IDENTIFIED BY '${FLUXUSER_MYSQL_PASSWORD}';"
        mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "ALTER USER 'fluxuser'@'localhost' IDENTIFIED WITH mysql_native_password BY '${FLUXUSER_MYSQL_PASSWORD}';"
        mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "GRANT ALL PRIVILEGES ON \`${FLUX_DATABASE_NAME}\` . * TO 'fluxuser'@'localhost' WITH GRANT OPTION;FLUSH PRIVILEGES;"
        mysql -uroot -p${MYSQL_ROOT_PASSWORD} flux < ${FLUX_SOURCE_DIR}/database/flux-6.0.sql
        mysql -uroot -p${MYSQL_ROOT_PASSWORD} flux < ${FLUX_SOURCE_DIR}/database/flux-6.0.1.sql
}

#Install SSL for security

install_ssl()
{
                read -n 1 -p "Do you want to install and configure ssl cert ? (y/n) "
                if [ "$REPLY"   = "y" ]; then
                        if [ -f /etc/debian_version ] ; then
							DIST="DEBIAN"
							python3-certbot-nginx python3-certbot
							certbot -m suporte@flux.net.br --nginx -d ${FLUX_HOST_DOMAIN_NAME} --agree-tos -n --no-redirect certonly -q
							sed "s@ssl_certificate[ \t]*/etc/nginx/ssl/nginx.crt;@ssl_certificate /etc/letsencrypt/live/${FLUX_HOST_DOMAIN_NAME}/fullchain.pem;@g" -i /etc/nginx/conf.d/flux.conf
							sed "s@ssl_certificate_key[ \t]*/etc/nginx/ssl/nginx.key;@ssl_certificate_key /etc/letsencrypt/live/${FLUX_HOST_DOMAIN_NAME}/privkey.pem;@g" -i /etc/nginx/conf.d/flux.conf
							sed -i "s#server_name _#server_name ${FLUX_HOST_DOMAIN_NAME}#g" /etc/nginx/conf.d/flux.conf
                        elif  [ ${DIST} = "DEBIAN10" ]; then
                           python3-certbot-nginx python3-certbot
                            certbot -m suporte@flux.net.br --nginx -d ${FLUX_HOST_DOMAIN_NAME} --agree-tos -n --no-redirect certonly -q
                            sed "s@ssl_certificate[ \t]*/etc/nginx/ssl/nginx.crt;@ssl_certificate /etc/letsencrypt/live/${FLUX_HOST_DOMAIN_NAME}/fullchain.pem;@g" -i /etc/nginx/conf.d/flux.conf
                            sed "s@ssl_certificate_key[ \t]*/etc/nginx/ssl/nginx.key;@ssl_certificate_key /etc/letsencrypt/live/${FLUX_HOST_DOMAIN_NAME}/privkey.pem;@g" -i /etc/nginx/conf.d/flux.conf
                            sed -i "s#server_name _#server_name ${FLUX_HOST_DOMAIN_NAME}#g" /etc/nginx/conf.d/flux.conf
                            
                        elif [ -f /etc/redhat-release ] ; then
                                DIST="CENTOS"
						python3-certbot-nginx python3-certbot
						certbot -m suporte@flux.net.br --nginx -d ${FLUX_HOST_DOMAIN_NAME} --agree-tos -n --no-redirect certonly -q
						sed "s@ssl_certificate[ \t]*/etc/nginx/ssl/nginx.crt;@ssl_certificate /etc/letsencrypt/live/${FLUX_HOST_DOMAIN_NAME}/fullchain.pem;@g" -i /etc/nginx/conf.d/flux.conf
						sed "s@ssl_certificate_key[ \t]*/etc/nginx/ssl/nginx.key;@ssl_certificate_key /etc/letsencrypt/live/${FLUX_HOST_DOMAIN_NAME}/privkey.pem;@g" -i /etc/nginx/conf.d/flux.conf
						sed -i "s#server_name _#server_name ${FLUX_HOST_DOMAIN_NAME}#g" /etc/nginx/conf.d/flux.conf        
                        fi
                        echo "################################################################"
                        systemctl restart nginx
                        systemctl enable nginx
                        echo "################################################################"
                        echo "SSL Cert Install completed"
                        else
                        echo ""
                        echo "SSL Cert installation is aborted !"
                fi   
}

#Remove all downloaded and temp files from server
clean_server ()
{
        cd /usr/src
        rm -rf GNU-AGPLv3.6.txt install.sh mysql80-community-release-el7-1.noarch.rpm
        echo "FS restarting...!"
        systemctl restart freeswitch
        echo "FS restarted...!"
}

#Installation Information Print
start_installation ()
{
        get_linux_distribution
        verification
        install_prerequisties
        license_accept
        get_flux_source
        get_user_response
        install_mysql
        normalize_mysql
        install_freeswitch
        install_php
        install_flux
        install_database
        normalize_freeswitch
        normalize_flux
        install_ssl
        clean_server
        clear
        echo "******************************************************************************************"
        echo "******************************************************************************************"
        echo "******************************************************************************************"
        echo "**********                                                                      **********"
        echo "**********           Your FLUX is installed successfully                       **********"
        echo "                     Browse URL: https://${FLUX_HOST_DOMAIN_NAME}"
        echo "                     Username: admin"     
        echo "                     Password: admin"
        echo ""
        echo "                     MySQL root user password:"
        echo "                     ${MYSQL_ROOT_PASSWORD}"                                       
        echo ""
        echo "                     MySQL fluxuser password:"
        echo "                     ${FLUXUSER_MYSQL_PASSWORD}" 
        echo ""               
        echo "**********           IMPORTANT NOTE: Please reboot your server once.            **********"
        echo "**********                                                                      **********"
        echo "******************************************************************************************"
        echo "******************************************************************************************"
        echo "******************************************************************************************"
}
start_installation
