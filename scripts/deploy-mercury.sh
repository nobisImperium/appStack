#0 Script initialization
### Static Steelscript Vars
linuxos="redhat-release"

############################################################################################
#1 Install all platform prerequisites: Essentially a LAMP Stack and Development Tools

	# Base Packages System/Wide/Libs/etc
	# sudo yum clean all
	# Enable EPEL Release and Software Collections Repos
	#sudo yum -y install epel-release centos-release-scl
	# On RHEL, enable RHSCL repository for you system:
	# sudo yum-config-manager --enable rhel-server-rhscl-7-rpms
	# install Development Tools
	sudo yum -y groupinstall 'Development Tools'
	# Install RedHat Python 3.6
	# sudo yum -y install rh-python36
	# enable software collection PHP in bash
	# scl enable rh-php71 bash
	# Install python virtualenv package
	# sudo yum -y install python-virtualenv
	#### Install 'pip' Python Package Installer from - https://pip.pypa.io/en/stable/
	# sudo wget "https://bootstrap.pypa.io/get-pip.py" -O /tmp/get-pip.py
	# sudo python /tmp/get-pip.py
	# clean up temp file
	# rm -f /tmp/get-pip.py


# Add the GitLab package repository and install the package
# curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.rpm.sh | sudo bash

# Install gitlab, accessible via hostmane/url provided
# sudo EXTERNAL_URL="http://windowpane-mercury.usgovvirginia.cloudapp.usgovcloudapi.net/" yum install -y gitlab-ee

# Enable Foreman repo
# sudo yum -y install https://yum.theforeman.org/releases/1.20/el7/x86_64/foreman-release.rpm

# Install Foreman Installer
# sudo yum -y install foreman-installer

# install Foreman
# sudo foreman-installer

# Add the PostgreSQL repo
#        sudo rpm -Uvh https://yum.postgresql.org/10/redhat/rhel-7-x86_64/pgdg-centos10-10-2.noarch.rpm
# Install PostgreSQL server
#        sudo yum install -y postgresql10

# Add the Puppet packet repository
# sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
# Install puppetserver (Master)
# sudo yum -y install puppetserver

exit 0
