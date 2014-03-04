#!/bin/bash

set -e

rm -f centos65-x64.virtualbox.box
packer build -only virtualbox-iso packer.json
vagrant box remove centos65-x64 || true
vagrant box add centos65-x64 centos65-x64.virtualbox.box
