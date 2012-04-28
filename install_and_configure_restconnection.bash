#!/bin/bash -e

# RightScript: Install & configure RestConnection
#
# Description: Installs and configures the RestConnection helper for use with the RightScale API.
#
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

: "${RC_RS_ACCOUNT_ID:?not set, exiting.}"
: "${RC_RS_USERNAME:?not set, exiting.}"
: "${RC_RS_PASSWORD:?not set, exiting.}"

config_dir="$HOME/.rest_connection"
api_version="1.0"

# Install ruby, rubygems
#apt-get -y install ruby rubygems      # the packages field is being used

hash gem || { echo 'gem front end not found in path, exiting.' >&2; exit 1; }

#  install rest_connection build/install deps
case "$RS_DISTRO" in
centos)
	yum -y install libxml2 libxml2-devel libxslt-devel
    ;;
ubuntu|debian)
	apt-get -y install libxml2 libxml2-dev libxslt-dev
    ;;
esac

# Install rest_connection (and i18n which is required)
gem install rest_connection i18n --no-rdoc --no-ri

mkdir -p "$config_dir"
touch "$config_dir"/rest_api_config.yaml
chmod -Rv 700 "$config_dir"

# Configure rest_connection
cat <<EOF> "$config_dir"/rest_api_config.yaml
---
:ssh_keys: 
- ~/.ssh/my_server_key
- ~/.ssh/my_server_key-eu
- ~/.ssh/my_server_key-west
:pass: $RC_RS_PASSWORD
:user: $RC_RS_USERNAME
:api_url: https://my.rightscale.com/api/acct/$RC_RS_ACCOUNT_ID
:common_headers: 
  X_API_VERSION: "$api_version"
EOF

echo 'Done.'