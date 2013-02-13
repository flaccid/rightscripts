#!/bin/bash -e

# RightScript: Install Amazon EC2 API Tools
#
# Description: Installs Amazon EC2 API Tools from the desired source.
# See http://developer.amazonwebservices.com/connect/entry.jspa?externalID=351
#
# Inputs:
# API_TOOLS_INSTALL_SOURCE			The source to install from - rpm, zip, repos
#
# Tested on Debian, Ubuntu, CentOS. Please submit a bug if you have an issue (https://forums.rightscale.com//forumdisplay.php?f=41).
#
# Dependencies:
# Requires alien if installing from RPM on a non-RPM system
# Author: Chris Fordham <chris.fordham@rightscale.com>

# Copyright (c) 2007-2008 by RightScale Inc., all rights reserved worldwide

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#
# Set input defaults
#
: ${API_TOOLS_INSTALL_SOURCE:=zip}

#
# functions
#
install_from_zip() {
	echo '(installing from zip)'
	cd /tmp
	wget -q http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip -O /tmp/ec2-api-tools.zip
	unzip -u ec2-api-tools.zip
	mkdir -pv /usr/local/ec2
	cd ./ec2-api-tools-*
	rsync -az ./* /usr/local/ec2
	cd /tmp
	rm -Rf /tmp/ec2-api-tools*
	ln -fs /usr/local/ec2/bin/* /usr/bin/
}

install_from_rpm() {
	echo '(installing from rpm)'
	echo "Unfortunately, Amazon no longer provides a noarch rpm. Suggestions for a new RPM welcome: https://forums.rightscale.com//forumdisplay.php?f=40."
	exit 1
	wget -q http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.noarch.rpm -O /tmp/ec2-api-tools.noarch.rpm    # installing directly with rpm -i fails on some distros
	if ! which rpm; then
		echo '(no rpm executable found in path, using alien)'
		alien -i --scripts /tmp/ec2-api-tools.noarch.rpm
	else
		rpm -iv /tmp/ec2-api-tools.noarch.rpm
	fi
	rm -v /tmp/ec2-api-tools.noarch.rpm
}

#
# Install Amazon EC2 API Tools
#
echo 'Installing Amazon EC2 API Tools...'
case "$API_TOOLS_INSTALL_SOURCE" in
	rpm)
		install_from_rpm
	;;
	zip)
		if [ "$RS_DISTRO" = 'debian' ]; then
			echo '(installing default JRE)'
			apt-get -y install unzip default-jre
		fi
		if [ "$RS_DISTRO" = 'ubuntu' ]; then
			echo '(installing openjdk-6-jre)'
			apt-get -y install unzip openjdk-6-jre
		fi
		install_from_zip
	;;
	repos)
		echo '(install from system repos)'
		case "$RS_DISTRO" in
			ubuntu)
				apt-get update && apt-get install -y ec2-api-tools
			;;
			debian)
 				echo 'Installing from zip file (ec2-api-tools does not exist in Debian).'
				echo '(installing default JRE)'
				apt-get install -y unzip default-jre
				install_from_zip
			;;
			centos)
				echo 'Installing from YUM repository (assumes package is available in current repos config).'
				yum -y install ec2-api-tools
			;;
			*)
				echo 'This OS/distro not yet supported, exiting.'
				exit 1
		esac
	;;
	*)
esac

echo 'Done.'