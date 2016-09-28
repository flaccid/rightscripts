#!/bin/sh -e

# RightScript: Tune Kernel Settings

# Inputs:
# $KERNEL_SETTINGS_SET - semi-colon separated kernel settings to set e.g. vm.swappiness=30;net.ipv4.ip_forward=1
# $KERNEL_SETTINGS_PERSIST - whether to save and persist the settings (default: true)
# $KERNEL_SETTINGS_CONF_FILE - the config file to persist the config to (default: /etc/sysctl.d/01-tuned.conf)

# Upstream/reference documentation:
# https://www.freedesktop.org/software/systemd/man/sysctl.d.html
# https://wiki.archlinux.org/index.php/sysctl

: ${KERNEL_SETTINGS_SET:=}
: ${KERNEL_SETTINGS_PERSIST:=true}
: ${KERNEL_SETTINGS_CONF_FILE:=/etc/sysctl.d/01-tuned.conf}

if [ -e "$KERNEL_SETTINGS_SET" ]; then
  echo '$KERNEL_SETTINGS_SET is empty, skipping.'
  exit 0
fi

echo 'Tuning kernel.'

if [ "$KERNEL_SETTINGS_PERSIST" = 'true' ]; then
  sudo mkdir -p /etc/sysctl.d
  echo "# set by $(basename $0)" | sudo tee "$KERNEL_SETTINGS_CONF_FILE" >/dev/null 2>&1
fi

settings=(${KERNEL_SETTINGS_SET//;/ })
for setting in "${settings[@]}"
do
  sudo sysctl -w "$setting"
  echo "$setting" | sudo tee -a "$KERNEL_SETTINGS_CONF_FILE" >/dev/null 2>&1
done

echo 'Done.'
