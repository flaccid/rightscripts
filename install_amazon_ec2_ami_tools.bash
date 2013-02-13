#! /bin/bash -e

# RightScript: Install Amazon EC2 AMI Tools
#
# Description: Installs Amazon EC2 AMI Tools from the desired source.
# See http://developer.amazonwebservices.com/connect/entry.jspa?externalID=368
#
# Inputs:
# AMI_TOOLS_INSTALL_SOURCE			The source to install from - rpm, zip, repos
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
# Linux detection
#
if [ -e /usr/bin/lsb_release ]; then
  case `lsb_release -si` in
    Ubuntu*) export RS_DISTRO=ubuntu
             export RS_BASE_OS=debian
			 echo 'Ubuntu detected.'
             ;;
    Debian*) export RS_DISTRO=debian
             export RS_BASE_OS=debian
			 echo 'Debian detected.'
             ;;
    CentOS*) export RS_DISTRO=centos
             export RS_BASE_OS=redhat
			 echo 'CentOS detected.'
             ;;
    Fedora*) export RS_DISTRO=redhat
             export RS_BASE_OS=redhat
			 echo 'Fedora detected.'
             ;;
    *)       export RS_DISTRO=unknown
             export RS_BASE_OS=unknown
             ;;
  esac
fi
echo

#
# Set input defaults
#
: ${AMI_TOOLS_INSTALL_SOURCE:=rpm}

#
# Install Amazon EC2 AMI Tools
#
cd /tmp
echo 'Installing Amazon EC2 AMI Tools...'
case "$AMI_TOOLS_INSTALL_SOURCE" in
	rpm)
		wget -q http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm
		if [ ! "$RS_DISTRO" = 'centos' ]; then
			alien -i --scripts /tmp/ec2-ami-tools.noarch.rpm
		else
			rpm -iv /tmp/ec2-ami-tools.noarch.rpm
		fi
		rm -v /tmp/ec2-ami-tools.noarch.rpm
	;;
	zip)
                cd /tmp
                wget -q http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.zip -O /tmp/ec2-ami-tools.zip
		unzip -u ec2-ami-tools.zip
                mkdir -pv /usr/local/ec2
                cd ./ec2-ami-tools-*
                rsync -az ./* /usr/local/ec2
                cd /tmp
		rm -Rf /tmp/ec2-ami-tools*
                ln -fs /usr/local/ec2/bin/* /usr/bin/
                [ ! -e /home/ec2 ] && ln -fsv /usr/local/ec2 /home/    # link to /home/ec2 for Ec2BundleWorker
	;;
	repos)
		case "$RS_DISTRO" in
			ubuntu|debian)
				apt-get update && apt-get install -y ec2-ami-tools
			;;
			centos)
				echo 'CentOS support is coming.'
				exit 1
			;;
			*)
				echo 'This distro not yet supported.'
				exit 1
		esac
	;;
	*)
esac

echo 'Done.'