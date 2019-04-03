#0 Script initialization
### Static Steelscript Vars
linuxos="redhat-release"

############################################################################################
#1 Install all platform prerequisites: Essentially a LAMP Stack and Development Tools

	# Base Packages System/Wide/Libs/etc
	sudo yum clean all
	# Enable EPEL Release and Software Collections Repos
	sudo yum -y install epel-release centos-release-scl
	# On RHEL, enable RHSCL repository for you system:
	sudo yum-config-manager --enable rhel-server-rhscl-7-rpms
	# enable software collection in bash
	scl enable rh-php71 bash
	# install Development Tools
	sudo yum -y groupinstall 'Development Tools'
	# Install RedHat Python 3.6
	sudo yum -y install rh-python36
	# Install python virtualenv package
	sudo yum -y install python-virtualenv
	# install QT (required later for PGAdmin)
	sudo yum -y install qt
	sudo yum -y install qt-devel

	#### Install 'pip' Python Package Installer from - https://pip.pypa.io/en/stable/
	sudo wget "https://bootstrap.pypa.io/get-pip.py" -O /tmp/get-pip.py
	sudo python /tmp/get-pip.py
	# clean up temp file
	rm -f /tmp/get-pip.py


# "LAMP" Stack Requirements - we MUST use a "Modern" release of PHP >= 7.0 for security and compatibility needs. Install PHP 7.1 Modules and Apache 2.4 from Software Collections Library for CentOS 7
	sudo yum -y install rh-php71 rh-php71-php rh-php71-php-bcmath rh-php71-php-cli rh-php71-php-common rh-php71-php-dba rh-php71-php-embedded rh-php71-php-enchant rh-php71-php-fpm rh-php71-php-gd rh-php71-php-intl \
	rh-php71-php-ldap rh-php71-php-mbstring rh-php71-php-mysqlnd rh-php71-php-odbc rh-php71-php-pdo rh-php71-php-pear rh-php71-php-pecl-apcu rh-php71-php-pgsql rh-php71-php-process rh-php71-php-pspell rh-php71-php-recode \
	rh-php71-php-snmp rh-php71-php-soap rh-php71-php-xml rh-php71-php-xmlrpc sclo-php71-php-imap sclo-php71-php-mcrypt sclo-php71-php-pecl-amqp sclo-php71-php-pecl-apcu-bc sclo-php71-php-pecl-apfd sclo-php71-php-pecl-geoip \
	sclo-php71-php-pecl-http sclo-php71-php-pecl-igbinary sclo-php71-php-pecl-imagick sclo-php71-php-pecl-lzf sclo-php71-php-pecl-memcached sclo-php71-php-pecl-mongodb sclo-php71-php-pecl-msgpack sclo-php71-php-pecl-propro \
	sclo-php71-php-pecl-raphf sclo-php71-php-pecl-redis sclo-php71-php-pecl-selinux sclo-php71-php-pecl-solr2 sclo-php71-php-pecl-uploadprogress sclo-php71-php-pecl-uuid sclo-php71-php-pecl-xattr sclo-php71-php-pecl-xdebug \
	sclo-php71-php-tidy httpd24 httpd24-mod_ssl
	# Stop regular redhat-release httpd service if present, disable for subsequent boots into this runlevel
	sudo systemctl stop httpd.service
	sudo systemctl disable httpd.service

# Create a custom systemd httpd.service file for apache2.4 from Software Collections Library
cat <<EOF > /etc/systemd/system/httpd.serviee
[Unit]
Description=The RedHat Software Collections Library (SCL) Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)
[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd
ExecStart=/opt/rh/httpd24/root/usr/sbin/httpd-scl-wrapper \$OPTIONS -DFOREGROUND
ExecReload=/opt/rh/httpd24/root/usr/sbin/httpd-scl-wrapper \$OPTIONS -k graceful
ExecStop=/bin/kill -WINCH \${MAINPID}
# We want systemd to give httpd some time to finish gracefully, but still want it to kill httpd after TimeoutStopSec if something went wrong during the graceful stop. Normally, Systemd sends SIGTERM signal right after the
# ExecStop, which would kill httpd. We are sending useless SIGCONT here to give httpd time to finish.
KillSignal=SIGCONT
PrivateTmp=true
[Install]
WantedBy=multi-user.target
EOF

# Create the systemctl EnvironmentFile for httpd.service, set proper perms
cat <<EOF > /etc/sysconfig/httpd
OPTIONS="-d /etc/httpd"
LANG=C
EOF
chmod 644 /etc/sysconfig/httpd

# Copy the httpd24 files to /etc/httpd and modify them
	if [ -d /etc/httpd ] && [ ! -d /etc/httpd.base ]; then (mv /etc/httpd /etc/httpd.base); fi # artifacts may exist, e.q. conf.d/squid.conf
	if [ ! -f /etc/httpd/conf/httpd.conf ]; then (rsync -avp /opt/rh/httpd24/root/etc/httpd/ /etc/httpd/); fi # don't accidentally overwrite httpd.conf (et al)
# Prefer /var/www as DocumentRoot
	for httpd24_conf in $(find /etc/httpd -type f | xargs grep -l "/opt/rh/httpd24/root"); do echo $httpd24_conf; sed -i -e 's#/opt/rh/httpd24/root/etc#/etc#g' -e 's#/opt/rh/httpd24/root/var/www#/var/www#g' $httpd24_conf;
done

# Use /var/log/httpd directory for logs and ensure /etc/httpd/logs points there
	rm -f /etc/httpd/logs && ln -s /var/log/httpd /etc/httpd/logs
# Preserve the original SCL config. After years and years of /etc/php.ini, it’s become finger memory for many. It’s hard coded into lots of stuff that looks for it here, too.
	if [ ! -f /etc/php.ini ]; then (cp /etc/opt/rh/rh-php71/php.ini /etc/php.ini); fi # don't accidentally overwrite php.ini
	grep -q -i -F '^PHPIniDir' /etc/httpd/conf.d/rh-php71-php.conf || (echo; echo 'PHPIniDir /etc/php.ini') >> /etc/httpd/conf.d/rh-php71-php.conf
# Reload all daemons
	sudo systemctl daemon-reload
# Enable httpd-24-httpd
	sudo systemctl enable httpd24-httpd
# Start httpd-24-httpd service
	sudo systemctl start httpd24-httpd

# Add the rh-php71 shared library directories to the ld linker search path via /etc/ld.so.conf.d/rh-php71.conf
cat <<EOF > /etc/ld.so.conf.d/rh-php71.conf
/opt/rh/rh-php71/root/usr/lib64
/opt/rh/httpd24/root/usr/lib64
/opt/rh/rh-php71/root/usr/lib
/opt/rh/httpd24/root/usr/lib
EOF

# Prefix the rh-php71 binary directories to all login PATHs via /etc/profile.d/zzzz-scl.sh
touch /etc/profile.d/zzzz-scl.sh
cat <<EOF /etc/profile.d/zzzz-scl.sh
if [ -d /opt/rh/ ] && [ -r /opt/rh/ ]; then
    Rhscl_Roots=$(find /opt/rh/ -type f -name enable 2> /dev/null | sort -V)
    for Rhscl_Enable in $Rhscl_Roots; do
       	if [ -r "$Rhscl_Enable" ]; then
            . "$Rhscl_Enable"
        else
            continue
        fi
        Rhscl_Root="$(dirname "$Rhscl_Enable")/root"
        Rhscl_Bins="usr/bin usr/sbin bin sbin"
        for Rhscl_Bin in $Rhscl_Bins; do
            if [ -d "$Rhscl_Root/$Rhscl_Bin" ]; then
                Scl_Path+="$Rhscl_Root/$Rhscl_Bin:"
            fi
        done
        unset Rhscl_Bin Rhscl_Bins Rhscl_Enable Rhscl_Root
    done
    unset Rhscl_Roots
fi
export PATH_SCL=$Scl_Path
export PATH=${PATH_SCL}:$PATH
EOF

# Many packages, programs, & utilities (and people) expect the default CentOS 7 filesystem locations for associated files. The RedHat SCL packages relocate everything to /opt/rh/. use a symbolic link
	ln -s /opt/rh/rh-php71/root/usr/bin/php /usr/bin/php

# Add Node.js Repo and Install Node.js
sudo /bin/curl -sL https://rpm.nodesource.com/setup_10.x | sudo bash -
sudo yum -y install nodejs

exit 0
