#!/bin/sh -ex

arch=`uname -m`
cloud=ec2

echo "Setting RightScale cloud to $cloud."
mkdir -p /etc/rightscale.d; echo -n "$cloud" > /etc/rightscale.d/cloud

echo 'Installing RightScale RightLink dependencies.'
rs_deps='git curl bash lsb-release bind-utils'
zypper -n install $rs_deps || yum -y install $rs_deps

cd /tmp
rpms=$(curl -s http://mirror.rightscale.com/rightlink/latest_redhatenterpriseserver/ | perl -0ne 'print "$1\n" while (/<a\s*href\s*=\s*\"(.*?)\">.*?<\/a>/igs)' | grep .rpm | grep "$arch") && rpm=$(grep "$arch" <<<"$rpms") && \
echo Installing "$rpm". && rpm -iv "http://mirror.rightscale.com/rightlink/latest_redhatenterpriseserver/$rpm" || echo 'RightLink installation failed!'

echo 'Initialising RightScale RightLink...'
/etc/init.d/rightboot start
/etc/init.d/rightscale start
/etc/init.d/rightlink start