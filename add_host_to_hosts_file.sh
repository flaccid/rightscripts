#!/bin/sh -e

: "${FSTAB_ADD_HOST_NAME:=}"
: "${FSTAB_ADD_HOST_IP:=}"

[ -z "$FSTAB_ADD_HOST_NAME" ] && echo 'FSTAB_ADD_HOST_NAME not setting, skipping.' && exit 0

if grep -q "$FSTAB_ADD_HOST_NAME" /etc/hosts; then
  echo 'Updating host in fstab.'
  sudo sed -i "s/.*$FSTAB_ADD_HOST_NAME.*/$FSTAB_ADD_HOST_IP    $FSTAB_ADD_HOST_NAME/" /etc/hosts
else
  echo 'Adding host to fstab.'
  echo "$FSTAB_ADD_HOST_IP    $FSTAB_ADD_HOST_NAME" | sudo tee -a /etc/hosts >/dev/null 2>&1
fi

grep "$FSTAB_ADD_HOST_NAME" /etc/hosts

# we currently don't care if the ping fails
ping -c 3 "$FSTAB_ADD_HOST_NAME" || true

echo 'Done.'
