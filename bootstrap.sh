#!/bin/bash

# Install Puppet on Centos 6.5:

yum update

# Install Puppet
rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm
yum install puppet-server

# Install r10k
gem install r10k

# Populate Puppetfile file
(
cat << EOF
# Puppet
mod 'puppetmaster', :git => 'https://github.com/opticpow/puppet-puppetmaster.git'

EOF
) > /etc/puppet/Puppetfile

# Install Remote Modules
r10k puppetfile install

# Hosts file
puppet apply --modulepath=/etc/puppet/modules -e "include puppetmaster"

service puppetmaster restart




