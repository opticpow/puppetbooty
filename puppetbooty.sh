#!/bin/bash
################################################################################
#
# puppetboot.sh - A script to boo strap puppet on a minimal server
#
# https://github.com/opticpow/puppetbooty
#
# Copyright 2014 Wayne Ingram
#
# License https://github.com/opticpow/puppetbooty/LICENSE
#
################################################################################
# Setup ANSI Colours

RCol='\e[0m' # Text Reset
# Regular       Bold             Underline        High Intensity   BoldHigh Intens   Background       High Intensity Backgrounds
Bla='\e[0;30m'; BBla='\e[1;30m'; UBla='\e[4;30m'; IBla='\e[0;90m'; BIBla='\e[1;90m'; On_Bla='\e[40m'; On_IBla='\e[0;100m'
Red='\e[0;31m'; BRed='\e[1;31m'; URed='\e[4;31m'; IRed='\e[0;91m'; BIRed='\e[1;91m'; On_Red='\e[41m'; On_IRed='\e[0;101m'
Gre='\e[0;32m'; BGre='\e[1;32m'; UGre='\e[4;32m'; IGre='\e[0;92m'; BIGre='\e[1;92m'; On_Gre='\e[42m'; On_IGre='\e[0;102m'
Yel='\e[0;33m'; BYel='\e[1;33m'; UYel='\e[4;33m'; IYel='\e[0;93m'; BIYel='\e[1;93m'; On_Yel='\e[43m'; On_IYel='\e[0;103m'
Blu='\e[0;34m'; BBlu='\e[1;34m'; UBlu='\e[4;34m'; IBlu='\e[0;94m'; BIBlu='\e[1;94m'; On_Blu='\e[44m'; On_IBlu='\e[0;104m'
Pur='\e[0;35m'; BPur='\e[1;35m'; UPur='\e[4;35m'; IPur='\e[0;95m'; BIPur='\e[1;95m'; On_Pur='\e[45m'; On_IPur='\e[0;105m'
Cya='\e[0;36m'; BCya='\e[1;36m'; UCya='\e[4;36m'; ICya='\e[0;96m'; BICya='\e[1;96m'; On_Cya='\e[46m'; On_ICya='\e[0;106m'
Whi='\e[0;37m'; BWhi='\e[1;37m'; UWhi='\e[4;37m'; IWhi='\e[0;97m'; BIWhi='\e[1;97m'; On_Whi='\e[47m'; On_IWhi='\e[0;107m'

echo -e "${RCol}"

################################################################################
# Check to see if we have already run
if [[ -f /.puppetbooty ]]
then
    echo -e "\n\n Server has already been deployed. Enjoy\n\n"
    exit 0
fi

################################################################################
# Default Variables
logfile="/root/puppetbooty.log"
domain="ingram.internal"
ip=$(ip addr | awk '/inet/ && /eth0/{sub(/\/.*$/,"",$2); print $2}')

################################################################################
# Setup Log File
date > $logfile

################################################################################
# Some Handy Functions
function usage()
{
    warning "Usage:\n    $0 --type [master | agent --master <hostname>] [--proxy] [--update] [--hostname <hostname>]"
    exit 0
}

function pause()
{
	warning "Press Return to continue"
	read crap
}

function fail()
{
    echo -e "\n\n${Red}Operation Failed with return code $1, Check log file for error.${RCol}\n\n"
    exit 1
}

function notice()
{
    echo -e "\n${Gre}$1${RCol}\n"
}

function warning()
{
    echo -e "\n${Yel}$1${RCol}\n"
}

function info()
{
    echo -en "$1: "
}

function stat_skip()
{
    echo -e "[${Yel}SKIPPED${RCol}]"
}

function stat_ok()
{
    echo -e "[${Gre}  OK  ${RCol}]"
}

function stat_fail()
{
    echo -e "[${Red}Failed${RCol}]"
}

function doit()
{
    echo -e "\nExecuting: $1\n" >> $logfile
    eval $* >> $logfile 2>&1
    return $?
}

function docmd()
{
    info "$1"
    doit "$2"
    retval=$?
    case $retval in
        0)  stat_ok
            ;;
        *)  stat_fail
            fail $retval
            ;;
    esac
}

function dorpminst()
{
    info "Installing RPM file $1"
    doit "rpm -ivh $1"
    retval=$?
    case $retval in
        0)  stat_ok
            ;;
        1)  stat_skip
            ;;
        *)  stat_fail
            fail $retval
            ;;
    esac
}

function dopuppetrun()
{
    info "Running Puppet"
    doit "puppet agent --test"
    retval=$?
    case $retval in
        0)  stat_ok
            ;;
        1)  stat_ok
            warning "Puppet is waiting for cert. Please sign on master"
            ;;
        *)  stat_fail
            fail $retval
            ;;
    esac
}

function doyuminst()
{
    info "Installing Package $1"
    doit "yum -y install $1"
    retval=$?
    case $retval in
        0)  stat_ok
            ;;
        *)  stat_fail
            fail $retval
            ;;
    esac
}

warning "Executing PuppetBooty Provisioner script"

################################################################################
# Process Command Line Arguments
# NOTE: This requires GNU getopt.

ARGS=$(getopt -o h:t:m:pu --long hostname:,type:,master:,proxy,update -n "$0" -- "$@")

# Bad Arguments
if [ $? != 0 ]
then
    fail $?
    exit 1
fi

# Note the quotes around `$ARGS': they are essential!
eval set -- "$ARGS"

while true; do
    case "$1" in
        -h | --hostname) hostname="$2"; shift 2 ;;
        -t | --type)     Type="$2"; shift 2 ;;
        -m | --master)   Master="$2"; shift 2 ;;
        -p | --proxy)    Proxy="True"; shift ;;
        -u | --update)   Update="True"; shift ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done

if [ -z $Type ]
then
    usage
fi

################################################################################
# Work Out OS

if [[ -f /etc/centos-release ]]
then
    os="centos"
fi
if [[ -f /etc/SuSE-release ]]
then
    os="suse"
fi
if [[ -z $os ]]
then
     echo -e "\n\n${Red}Unknow Operating System${RCol}\n\n"
     exit 1
fi

warning "We are running on $os"

################################################################################
# Hostname

# Hosts file
notice "Basic Server Configuration"

if [[ -z $hostname ]]
then
    hostname=$Type
fi

# Hosts file
docmd "Adding localhost to hosts file" "echo -e \"127.0.0.1\tlocalhost.localdomin    localhost\" > /etc/hosts"
docmd "Adding ${hostname} to hosts file" "echo -e \"${ip}\t${hostname}.${domain} ${hostname}\" >> /etc/hosts"

case "$os" in
    'centos')   docmd "Configuring /etc/sysconfig/network" "echo -e \"NETWORKING=yes\nHOSTNAME=${hostname}.${domain}\" > /etc/sysconfig/network"
                docmd "Configuring resolv.conf" 'echo -e "\nappend domain-search \"nibdom.com.au\";" >> /etc/dhcp/dhclient-eth0.conf'
                ;;
      'suse')   docmd "Configuring /etc/HOSTNAME" "echo \"${hostname}.${domain}\" > /etc/HOSTNAME"
                docmd "Configuring resolv.conf" "echo -e \"search nibdom.com.au\" >> /etc/resolv.conf"
                ;;
esac
docmd "Setting Hostname" "hostname ${hostname}.${domain}"
docmd "Restarting Network" "service network restart"


################################################################################
# Setup Proxy

if [[ $Proxy == "True" ]]
then
	notice "Setting up Proxy"
	dorpminst /vagrant/cntlm/cntlm*rpm
	docmd "Installing Config file" "cp /vagrant/cntlm/cntlm.conf /etc"
	docmd "Starting Proxy service" "service cntlmd start"

	export http_proxy="http://localhost:3128"
	export https_proxy=$http_proxy

	echo 'export http_proxy="http://localhost:3128"' >> /etc/bashrc
	echo 'export https_proxy="http://localhost:3128"' >> /etc/bashrc

fi

notice "Update Operating System"
if [[ $Update == "True" ]]
then
    docmd "Yum Update" "yum -y update"
else
    info "Yum Update"
    stat_skip
fi

if [[ $Type == "master" ]]
then
    # Install Puppet
	notice "Installing Puppet"
	dorpminst http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm
	dorpminst http://mirror.rackcentral.com.au/epel/6/x86_64/epel-release-6-8.noarch.rpm
	doyuminst puppet-server
	doyuminst git
	doyuminst httpd

    # Install r10k
	notice "Install r10k"
	doit "gem install r10k"

    # Populate Puppetfile file
	echo "Creating Puppetfile"
(
cat << EOF
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
	notice "Installing Remote Modules"
	( cd /etc/puppet && r10k puppetfile install )

    # site.pp
	notice "Creating site.pp"

(
cat << EOF
# Inital site.pp to bootstrap dynamic environments
node default {
  notify { "!!! NO HOST ENTRY FOUND. PLEASE UPDATE NODES.PP WITH THIS NODE TYPE !!!": }
}

node ${hostname} {
  class { 'puppet':
    mode            => 'server',
    server          => '${hostname}.${domain}',
    dns_alt_names   => '${hostname}.${domain},${hostname},puppet',
    #prerun_command  => 'r10k deploy environment -p',
    module_path     => '/etc/puppet/environments/\$environment/modules',
    manifest_path   => '/etc/puppet/environments/\$environment/manifests/site.pp',
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
        sources => {
            'opticpow' => {
                'remote' => 'https://github.com/opticpow/puppet-mypuppet.git',
                'basedir' => '/etc/puppet/environments'
        }
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


    # Bootstrap Puppet
	notice "Bootstrapping Puppet"
	puppet apply --modulepath=/etc/puppet/modules -e "class { puppet: mode => server, server => '`hostname`', dns_alt_names => '`hostname`,`hostname -s`,puppet', autosign => true, runmode => 'manual' }" || fail

	notice "Restarting puppetmaster service"
	service puppetmaster restart || fail

    # Now run puppet over site.pp to setup passenger & r10k
	notice "Doing puppet run to setup passenger & r10k"
	puppet agent --test

    # Fix services
	notice "Fixing Services"
	service puppetmaster stop
	service httpd start

    # Deploy the environment from git
	notice "Deploying Environment"
	r10k deploy environment -p -v || fail

    # Cleanup
	notice "Cleaning up Bootstrap crud"
	rm -rf /etc/puppet/modules
	rm -rf /etc/puppet/manifests/*
	rm -rf /etc/puppet/Puppetfile
else
    # Install Puppet
    notice "Installing Puppet"
    dorpminst http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm
    doyuminst puppet

    # Bootstrap Puppet
    notice "Bootstrapping Puppet"
    dopuppetrun
fi

docmd "Registering Completed Deployment" "touch /.puppetbooty"
notice "Done"

