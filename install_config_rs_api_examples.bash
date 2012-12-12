#!/bin/bash -e

# RightScript: Install & configure rs_api_examples
#
# Description: Installs rs_api_examples from GitHub and configures credentials in ~/.rightscale

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

: ${API_VERSION:=1.0}
: ${API_ACCOUNT_ID:=}
: ${API_USER:=}
: ${API_PASSWORD:=}

install_dir="$HOME/bin"     # non-root
#install_dir=/usr/bin       # root

mkdir -p "$install_dir"
cd /tmp
git clone git://github.com/flaccid/rs_api_examples.git
cp -vR /tmp/rs_api_examples/bin/* "$install_dir"/
chmod +x "$install_dir"/rs-*.sh
rm -Rf /tmp/rs_api_examples

for f in "$HOME"/{.bash_profile,.bash_login,.profile,.bashrc}; do
    if [[ -f $f ]]; then
        echo "PATH+=':$install_dir'" >> "$f"; break;
    fi
done

mkdir -p "$HOME/.rightscale"
PATH+=":$install_dir"

cat <<EOF> "$HOME/.rightscale/rs_api_config.sh"
rs_api_version=$API_VERSION
rs_api_cookie="$HOME/.rightscale/rs_api_cookie.txt"
EOF
cat <<EOF> "$HOME/.rightscale/rs_api_creds.sh"
rs_api_account_id=$API_ACCOUNT_ID
rs_api_user="$API_USER"
rs_api_password="$API_PASSWORD"
EOF