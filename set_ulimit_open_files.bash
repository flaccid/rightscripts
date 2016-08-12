#! /bin/bash -e

# Set system ulimits

# Description: Sets/prints the ulimits on the system.
#
# Author: Chris Fordham <chris.fordham@industrieit.com>

# Inputs:
# $ULIMITS          A semi-colon separated list of limits to set in /etc/security/limits.conf
#                   e.g. *,hard,nproc,32768;*,hard,memlock,1048576
# $ULIMITS_SET      Whether to set the ulimits provided
# $ULIMITS_REBOOT   Whether to reboot after setting the ulimits
# $ULIMITS_SERVICES_TO_RESTART  Comma separated list of system services to restart after setting limits (optional)

: "${ULIMITS:=}"
: "${ULIMITS_REBOOT:=true}"
: "${ULIMITS_SET}:=true}"
: "${ULIMITS_SERVICES_TO_RESTART:=}"

if [ ! "$ULIMITS_SET" = 'true' ]; then
  echo '$ULIMITS_SET not set to true, skipping.'
  exit 0
fi

if [ -z "$ULIMITS" ]; then
  echo 'No ulimits provided, skipping.'
  exit 0
fi

ulimits=(${ULIMITS//;/ })

# display system ulimits
echo 'Current global ulimits:'
echo '--'
ulimit -a   # see all the kernel parameters
echo '--'
echo

if [ -e /etc/security/limits.d ]; then
  limit_file=/etc/security/limits.d/extra.conf
else
  limit_file=/etc/security/limits.conf
fi
sudo touch "$limit_file"
echo "Using $limit_file"

# make a copy of the existing file to see if we need to reboot at end
cp "$limit_file" /tmp/limit.conf.old

# remove the end of line line
sudo sed -i '/# End of file/d' "$limit_file"

for ulimit in "${ulimits[@]}"
do
  ulimit=$(echo "$ulimit" | tr , '\t\t')

  if ! grep "$ulimit" "$limit_file"; then
    echo "$ulimit" | sudo tee -a "$limit_file"
  fi
done

# add the end of line line
sudo sed -i '/^$/d' "$limit_file"
echo "" | sudo tee -a "$limit_file"
echo "# End of file" | sudo tee -a "$limit_file"

# display the new ulimits file
echo "New ulimits file ($limit_file):"
echo '--'
cat "$limit_file"
echo '--'
echo

diff /tmp/limit.conf.old "$limit_file" && echo "(no changes to existing file)"

# restart system services if specified
# currently we rely on the service command
if ! diff /tmp/limit.conf.old "$limit_file"; then
  if [ ! -z "$ULIMITS_SERVICES_TO_RESTART" ]; then
    ULIMITS_SERVICES_TO_RESTART=(${ULIMITS_SERVICES_TO_RESTART//,/ })

    for service in "${ULIMITS_SERVICES_TO_RESTART[@]}"
    do
      if [ "$service" = 'rightlink' ]; then
        echo 'Backgrounding restart of rightlink service (180 seconds)'
        exec $(sleep 180; sudo service "$service" restart &)&
      else
        echo "Restarting ${service}..."
        sudo service "$service" restart
      fi
    done
  else
    echo 'Skipping service restart(s) as there is no ulimits change.'
  fi
fi

if ! diff /tmp/limit.conf.old "$limit_file"; then
  if [ "$ULIMITS_REBOOT" = 'true' ]; then
    echo 'Backgrounding reboot command (60 seconds)'
    exec $(sleep 60; sudo reboot &)&
  else
    echo 'IMPORTANT: A system reboot still may be required to effect changes.'
  fi
elif [ "$ULIMITS_REBOOT" = 'true' ]; then
  echo 'Skipping reboot as there is no change to the limits file.'
  exit 0
fi

echo 'Done.'
