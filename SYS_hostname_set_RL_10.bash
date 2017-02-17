#!/bin/bash -e

# Copyright (c) 2015 RightScale, Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# 'Software'), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# Inputs:
# $HOSTNAME
# $DOMAINNAME

# shellcheck source=/dev/null
source "$RS_ATTACH_DIR/rs_distro.sh"

# we need the host command
type host > /dev/null 2>&1 || ( type yum > /dev/null 2>&1 && sudo yum -y install bind-utils || sudo apt-get -y install dnsutils )

#
# Drop to lower case, since hostnames should be lc anyway.
#
HOSTNAME=$(echo $HOSTNAME | tr "[:upper:]" "[:lower:]")

#
# Check for a numeric suffix (like in a server array)
# example:  array name #1
#
if [ "$(echo $HOSTNAME | grep '#' -c )" -gt 0 ]; then
  numeric_suffix=$(echo $HOSTNAME | cut -d'#' -f2)
else
  # no suffix
  numeric_suffix=''
fi

# Strip off a leading "-"'s or leading whitespace, if there is any.
HOSTNAME=${HOSTNAME##*( |-)}

# Clean up the hostname, so we can put labels after hostnames
# with no problems (like 'joebob.example.net MY COMMENT')
HOSTNAME=$(echo $HOSTNAME | cut -d' ' -f 1)

# Underscores are illegal in hostnames, so change them to dashes.
HOSTNAME=$(echo $HOSTNAME | sed "s/_/-/g")

# Append a numeric suffix to the sname, if we have one.
if [ ! -z $numeric_suffix ]; then
  echo "Appending array suffix $numeric_suffix to the sname"
  sname=$(echo $HOSTNAME | cut -d'.' -f 1)
  dname=${HOSTNAME#"$sname"}

  HOSTNAME="$sname-$numeric_suffix$dname"
else
  echo "No suffix found, not appending anything."
fi

# append domain name and make it a fully qualified domain name
fqdn="$HOSTNAME.$DOMAINNAME"

echo "setting hostname to $fqdn ($HOSTNAME)"

# Set hostname & hostname-file (so it'll stick even after a DHCP update)
sudo hostname "$fqdn"
# https://www.freedesktop.org/software/systemd/man/hostname.html (should not contain dots, so short hostname only)
echo "$HOSTNAME" | sudo tee /etc/hostname

# ensure valid localhost entry
sudo sed -i "s%^127.0.0.1.*%127.0.0.1 localhost.localdomain localhost%" /etc/hosts

# get the ip address from eth0
ip_addr="$(ip addr | grep 'scope global eth0' | awk '{print $2}' | cut -f1 -d'/')" || true

if [ ! -z "$ip_addr" ]; then
  if grep "$ip_addr" /etc/hosts; then
    sudo sed -i "s%^$ip_addr.*%$ip_addr $fqdn $HOSTNAME%" /etc/hosts
  else
    echo "$ip_addr    $fqdn $HOSTNAME" | sudo tee -a /etc/hosts
  fi
fi

echo 'Done.'
