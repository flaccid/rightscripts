#!/usr/bin/ruby

# RightScript: Print shell environment (Ruby)
#
# Description: Prints the shell environment variables from ENV.
#
# Inputs:
# (none)
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

rs_profile_dir = "#{ENV['HOME']}/.rightscale"
env_script = "#{rs_profile_dir}/agent_env.rb"
home_dir = `echo ~`
current_user = `whoami`

# create ~/.rightscale
if ! FileTest::directory?(rs_profile_dir)
 Dir::mkdir(rs_profile_dir)
end

# create ~/.rightscale/agent_env.rb
File.open(env_script, 'w') { |f|
  ENV.each {|k,v|
    f.write("#{k} = \"#{v}\"\n")
  }
}

File.chmod(0700, env_script)
system("chmod +x #{env_script}")

puts "Current user: #{current_user}"
puts "Home directory (ENV['HOME']): #{ENV['HOME']}"
puts "Home directory (tilda): #{home_dir}"

puts 'Environment variables in ENV:'
puts '========================'
ENV.each {|k,v| puts "#{k}=#{v}"}
puts '========================'