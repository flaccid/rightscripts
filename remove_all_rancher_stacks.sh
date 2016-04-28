#! /bin/sh -e

# RightScript: Remove all Rancher stacks

# required inputs:
# $RANCHER_URL
# $RANCHER_ACCESS_KEY
# $RANCHER_SECRET_KEY

sudo mkdir -p /usr/local/bin
sudo cp -v "$RS_ATTACH_DIR/rancher-remove-all-stacks.py" /usr/local/bin/
sudo chmod +x /usr/local/bin/rancher-remove-all-stacks.py

export RANCHER_URL
export RANCHER_ACCESS_KEY
export RANCHER_SECRET_KEY

# ensure proxy/no proxy usage if required
. /etc/profile.d/*proxy* >/dev/null 2>&1 || true

sudo -E /usr/local/bin/rancher-remove-all-stacks.py

echo 'Done.'
