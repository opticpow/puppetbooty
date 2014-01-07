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
rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm
yum -y install puppet-server git

# Install r10k
echo "Install r10k"
gem install r10k

# Populate Puppetfile file
echo "Creating Puppetfile"
(
cat << EOF

# Puppet
mod 'hosts', :git => 'https://github.com/opticpow/puppet-hosts.git'

# example42/puppet
mod 'example42/puppet', '2.0.12'
mod 'example42/puppi', '2.1.6'
mod 'example42/apache', '2.1.3'
mod 'example42/mysql', '2.1.1'

# zack/r10k
mod 'zack/r10k', '0.0.7'
mod 'puppetlabs/ruby'
mod 'puppetlabs/stdlib'

#mod 'puppetlabs/puppetdb','3.0.0'

EOF
) > /etc/puppet/Puppetfile

# Install Remote Modules
echo "Installing Remote Modules"
( cd /etc/puppet && r10k puppetfile install )

# site.pp
echo "Creating site.pp"
hostname=`hostname -s`
fqdn=`hostname`

(
cat << EOF
# Inital site.pp to bootstrap dynamic environments
node default {
  notify { "!!! NO HOST ENTRY FOUND. PLEASE UPDATE NODES.PP WITH THIS NODE TYPE !!!": }
}

node ${hostname} {
  class { 'puppet':
    mode            => 'server',
    server          => '${fqdn}',
    dns_alt_names   => '${fqdn},${hostname},puppet',
    #prerun_command  => 'r10k deploy environment -p',
    module_path     => '/etc/puppet/environments/master/modules',
    manifest_path   => '/etc/puppet/environments/master/manifests/site.pp',
    passenger       => true,
    environment     => 'master',
    runmode         => 'manual',
  }

  file { '/etc/puppet/environments/':
      ensure => 'directory';
    '/var/cache/r10k':
      ensure => 'directory';
  }

  class {'r10k':
    version  => '1.1.1',
    cachedir => '/var/cache/r10k',
    sources  => {
      'opticpow'  => {
        'remote'  => 'https://github.com/opticpow/puppet-mypuppet.git',
        'basedir' => '/etc/puppet/environments'
      },
    },
    purgedirs => [
      "/etc/puppet/environments",
    ],
  }


  package {'git':
    ensure => 'present'
  }

}
EOF
) > /etc/puppet/manifests/site.pp

# Hosts file
rm -f /etc/hosts
touch /etc/hosts
puppet apply --modulepath=/etc/puppet/modules -e "include hosts"

# Bootstrap Puppet
puppet apply --modulepath=/etc/puppet/modules -e "class { puppet: mode => server, server => '`hostname`', dns_alt_names => '`hostname`,`hostname -s`,puppet', runmode => 'manual' }"

service puppetmaster restart

# Now run puppet over site.pp to setup passenger & r10k
puppet agent --test

# Fix services
echo "Fixing Services"
service puppetmaster stop
service httpd start

# Deploy the environment from git
echo "Deploying Environment"
r10k deploy environment -p -v

# Cleanup
echo "Cleaning up Bootstrap crud"
rm -rf /etc/puppet/modules
rm -rf /etc/puppet/manifests
rm -rf /etc/puppet/Puppetfile

echo "Done"

