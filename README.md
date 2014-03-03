puppetbooty
===========

Description
-----------


Puppetbooty is a script that bootstraps puppet onto a minimal linux server install. Currently it supports CentOS 6.x
There is also support for running within Vagrant, and support for using a proxy to allow access from behind corporate filewalls

Installation
------------

Just run the puppetboot.sh script on the installed server. It is self contained and needs only a minimal install. The server will need access to the internet to allow packages to be installed

Usage
-----

puppetbooty.sh --type [master | agent --master <hostname>] [--proxy] [--update] [--hostname <hostname>]

Examples
--------
bootstrap a puppet master:

  puppetbooty.sh --type master

bootstrap a puppet client with the master server ip 192.168.1.10

  puppetbooty.sh --type agent --master 192.168.1.10

