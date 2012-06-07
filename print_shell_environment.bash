#!/bin/bash

# RightScript: Print shell environment (Bash)
#
# Description: Prints the shell environment variables and optionally saves them to ~/.rightscale/agent_env.sh.
#
# Inputs:
# ENV_SAVE_TO_FILE		Whether to save the environment to ~/.rightscale/agent_env.sh (true/false; default=true)
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

: ${ENV_SAVE_TO_FILE:=true}

home_dir=~

if [ "$ENV_SAVE_TO_FILE" = 'true' ]; then
    env > ~/.rightscale/agent_env.sh
fi

echo "Current user: `whoami`"
echo "Home directory (\$HOME): $HOME"
echo "Home directory (tilda): $home_dir"
echo 

echo 'Printing shell variables (set):'
echo '=============================='
set
echo '=============================='
echo

echo 'Printing environment (env):'
echo '=============================='
env
echo '=============================='
echo

echo 'Done.'