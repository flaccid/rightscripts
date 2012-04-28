#!/bin/bash -e

# RightScript: Install rs-api-tools
#
# Description: Installs rs-api-tools from GitHub
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

install_dir="$HOME/bin"     # non-root
#install_dir=/usr/bin       # root

mkdir -p "$install_dir"
cd /tmp
git clone git://github.com/flaccid/rs-api-tools.git
cp -vR /tmp/rs-api-tools/bin/* "$install_dir"/
chmod +x "$install_dir"/rs-*
rm -Rf /tmp/rs-api-tools

for f in "$HOME"/{.bash_profile,.bash_login,.profile,.bashrc}; do
    if [[ -f $f ]]; then
        echo "PATH+=':$install_dir'" >> "$f"; break;
    fi
done

PATH+=":$install_dir"