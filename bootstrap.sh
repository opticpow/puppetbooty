#!/bin/bash

pause()
{
	echo "Press Return to continue"
	read crap
}

# Install Puppet on Centos 6.5:

export http_proxy="http://ntlvmbsm01.nibdom.com.au:3128"
export https_proxy=$http_proxy

echo "Update CentoS"
yum -y update


# Install Puppet
echo "Install Puppet"
rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-7.noarch.rpm
yum -y install puppet-server git

# Install r10k
echo "Install r10k"
gem install r10k

# Populate Puppetfile file
echo "Creating Puppetfile"
(
cat << EOF

# Puppet
#mod 'puppet', :git => 'https://github.com/opticpow/puppet-puppet.git'
mod 'hosts', :git => 'https://github.com/opticpow/puppet-hosts.git'
mod 'example42/puppet', '2.0.12'

mod 'hunner/hiera'

# Required for example42/puppet
mod 'example42/puppi', '2.1.6'
mod 'example42/apache', '2.1.3'
mod 'example42/mysql', '2.1.1'

mod 'zack/r10k', '0.0.7'

mod 'puppetlabs/puppetdb','3.0.0'

EOF
) > /etc/puppet/Puppetfile

# Install Remote Modules
echo "Installing Remote Modules"
PUPPETFILE=/etc/puppet/Puppetfile r10k puppetfile install

# site.pp
(
cat << EOF

node default {
  notify { "!!! NO HOST ENTRY FOUND. PLEASE UPDATE NODES.PP WITH THIS NODE TYPE !!!": }
}

node vagrant-centos65 {
  class { 'puppet':
    mode            => server,
    server          => 'vagrant-centos65',
    dns_alt_names   => 'vagrant-centos65,puppet',
  }

  file { '/etc/puppet/environments/':
      ensure => 'directory';
    '/var/cache/r10k':
      ensure => 'directory';
  }

  package {'git':
    ensure => 'present'
  }

}
) > /etc/puppet/manifests/site.pp

# Hosts file
rm -f /etc/hosts
touch /etc/hosts
puppet apply --modulepath=/etc/puppet/modules -e "include hosts"
#puppet apply --modulepath=/etc/puppet/modules -e "include puppetmaster"

#echo "Restarting Service"
#service puppetmaster restart




