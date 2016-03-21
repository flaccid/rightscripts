#! /bin/sh -e

# required inputs:
# $RANCHER_HOST_NAME (optional, defaults to the system's local hostname)
# $RANCHER_HOST_LABELS
# $RANCHER_URL
# $RANCHER_ACCESS_KEY
# $RANCHER_SECRET_KEY

sudo mkdir -p /usr/local/bin
sudo cp -v "$RS_ATTACH_DIR/rancher-set-labels-on-host.py" /usr/local/bin/
sudo chmod +x /usr/local/bin/rancher-set-labels-on-host.py

export RANCHER_HOST_NAME
export RANCHER_HOST_LABELS
export RANCHER_URL
export RANCHER_ACCESS_KEY
export RANCHER_SECRET_KEY

# ensure proxy/no proxy usage if required
. /etc/profile.d/*proxy* >/dev/null 2>&1 || true

sudo -E /usr/local/bin/rancher-set-labels-on-host.py

echo 'Done.'
