#! /bin/sh -e

# usage: configure_systemd-timesyncd.sh [nameserver nameserver..]

# configures systemd-timesyncd
# this script should be run as root

ntp_servers="$@"
[ -z "$ntp_servers" ] && ntp_servers=pool.ntp.org

echo "configuring to sync with: [$ntp_servers]"

cat <<EOF> /etc/systemd/timesyncd.conf
#  This file is part of systemd.
#
#  systemd is free software; you can redistribute it and/or modify it
#  under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation; either version 2.1 of the License, or
#  (at your option) any later version.
#
# Entries in this file show the compile time defaults.
# You can change settings by editing this file.
# Defaults can be restored by simply deleting this file.
#
# See timesyncd.conf(5) for details.

[Time]
NTP=$ntp_servers
FallbackNTP=0.pool.ntp.org 1.pool.ntp.org 0.fr.pool.ntp.org
EOF

timedatectl set-ntp true
systemctl restart systemd-timesyncd.service
sleep 5

echo ''
echo "- new status -"
echo "$(timedatectl status)"
systemctl status systemd-timesyncd.service
