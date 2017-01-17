#!/bin/bash -e

# $RANCHER_ENVIRONMENTS_CREATE
# $RANCHER_URL
# $RANCHER_ACCESS_KEY
# $RANCHER_SECRET_KEY

if [ -z "$RANCHER_ENVIRONMENTS_CREATE" ]; then
  echo '$RANCHER_ENVIRONMENTS_CREATE not set, skipping.'
  exit 0
fi

# jq is a dep.
if ! type jq > /dev/null 2>&1; then
  echo 'Installing jq...'
  compgen -G "/etc/profile.d/*proxy*" > /dev/null 2>&1 && source /etc/profile.d/*proxy* > /dev/null 2>&1
  curl -SsLk \
    --connect-timeout 5 \
    --max-time 30 \
    --retry 10 \
    --retry-delay 0 \
    --retry-max-time 120 \
      "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" | sudo tee /usr/local/bin/jq > /dev/null 2>&1
  sudo chmod +x /usr/local/bin/jq
  /usr/local/bin/jq --version
fi

# if rancher access key is not set, lets try to get the keys from tags on self
# Note:
# * rancher cli does not support no-auth anyway (for rancher servers with auth off);
# * note: this only works on rancher servers (not hosts) that have the tags
#         rancher:account_access_key
#         rancher:account_secret_key
if [ -z "$RANCHER_ACCESS_KEY" ]; then
  echo "Querying instance self..."
  instance_href=$(sudo /usr/local/bin/rsc --rl10 cm15 --x1 ':has(.rel:val("self")).href' index_instance_session /api/sessions/instance)
  server_href=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 show --x1 ':has(.rel:val("parent")).href' "$instance_href")
  cloud_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("cloud")).href')
  datacenter_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("datacenter")).href')
  echo "cloud href:      $cloud_href"
  echo "instance href:   $instance_href"
  echo "server href:     $server_href"
  echo "datacenter href: $datacenter_href"

  self_tags=$(sudo /usr/local/bin/rsc cm15 --rl10 by_resource /api/tags/by_resource \
    "resource_hrefs[]=$instance_href" --pp)
  account_access_key=$(echo "$self_tags" | jq --raw-output '.[][][] | select(.name | index("account_access_key")) .name' | cut -d = -f 2)
  account_secret_key=$(echo "$self_tags" | jq --raw-output '.[][][] | select(.name | index("account_secret_key")) .name' | cut -d = -f 2)

  export RANCHER_ACCESS_KEY="$account_access_key"
  export RANCHER_SECRET_KEY="$account_secret_key"
fi

echo "RANCHER_URL: $RANCHER_URL"
echo "RANCHER_ACCESS_KEY: $RANCHER_ACCESS_KEY"
echo "RANCHER_ENVIRONMENTS_CREATE: $RANCHER_ENVIRONMENTS_CREATE"

# create environment if not existing
IFS=, read -ra envs <<< "$RANCHER_ENVIRONMENTS_CREATE"
declare -p envs
for env in "${envs[@]}"
do
  # check if environment exists
  if ! rancher environment ls | awk -F ' ' '{print $2}' | grep -q "$env"; then
    if result=$(rancher environment create "$env"); then
      echo "Environment, '$env' ($result) successfully created."
    else
      echo 'Environment creation failed!'
      echo "$result"
      exit 1
    fi
  else
    echo "Environment, '$env' already exists, skipping creation."
  fi
done

echo 'Done.'
