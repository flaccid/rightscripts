#! /bin/bash -e

# we need bash here to avoid invalid non-zero exit with sh/dash
# when no source file is found by wildcard
source /etc/profile.d/*proxy* > /dev/null 2>&1 || true

if [ ! -z "$http_proxy" ]; then
  proxy_hostname=$(echo "$http_proxy" | awk -F/ '{print $3}' | cut -f1 -d":")
  if echo $(basename "$http_proxy") | grep ':' > /dev/null 2>&1; then
    proxy_port=$(echo ${http_proxy##*:} | tr -d '/')
  else
    proxy_port=80
  fi
  echo "Configuring proxy: $http_proxy"
  subscription-manager config --server.proxy_hostname="$proxy_hostname" --server.proxy_port="$proxy_port"
fi

if [ ! -z "$REDHAT_USER" ]; then
  [ -z "$REDHAT_POOL_ID" ] && opts='--auto-attach'

  sudo -E subscription-manager register --force --username="$REDHAT_USER" --password="$REDHAT_PASSWORD" "$opts"

  sudo -E subscription-manager list --available --all

  [ ! -z "$REDHAT_POOL_ID" ] && sudo -E subscription-manager attach --pool="$REDHAT_POOL_ID"
else
  echo 'No Red Hat user provided, skipping Red Hat system registration.'
  exit 0
fi

echo 'Done.'
