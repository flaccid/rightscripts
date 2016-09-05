#! /bin/sh -e

# Inputs:
# $RANCHER_URL
# $RANCHER_ACCESS_KEY
# $RANCHER_SECRET_KEY

export RANCHER_URL
export RANCHER_ACCESS_KEY
export RANCHER_SECRET_KEY

# exit if not terminating or stopping
if ([ ! -z "$DECOM_REASON" ] && [ "$DECOM_REASON" != 'terminate' ] && [ "$DECOM_REASON" != 'stop' ]); then
  echo 'server is not terminating or stopping, skipping.'
  exit 0
fi

# in case we need proxy settings
source /etc/profile.d/*proxy* > /dev/null 2>&1 || true

chmod +x "$RS_ATTACH_DIR/deactivate_and_delete_host.py"
"$RS_ATTACH_DIR/deactivate_and_delete_host.py"

echo 'Done.'
