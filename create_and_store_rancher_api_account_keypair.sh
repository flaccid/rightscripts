#!/bin/bash -ex

# WIP (not possible to work yet)

# currently only supports api version v2-beta

: ${RANCHER_HOST_PORT:=80}
: ${rancher_url_local:=http://localhost:$RANCHER_HOST_PORT}

api_version='v2-beta'

export no_proxy=127.0.0.1

# issue
# STDERR> 403 Forbidden
# STDERR> Permission denied: observer role is required
# check if keypair (by access key) already exists
#api_result=$(sudo /usr/local/bin/rsc \
#  --rl10 \
#  --dump=debug \
#  cm15 index credentials 'filter[]=name==RANCHER_ACCESS_KEY-ACCOUNT'
#)
#length=$(echo $api_result | jq 'length')
#[ "$length" -gt 0 ] && echo 'RightScale Credential, RANCHER_ACCESS_KEY-ACCOUNT alread exists, skipping.' && exit 0

# if jq is not installed, lets install the linux binary
if ! type jq > /dev/null 2>&1; then
  echo 'Installing jq...'
  source /etc/profile.d/*proxy* > /dev/null 2>&1 || true
  curl -SsLk "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" | sudo tee /usr/local/bin/jq > /dev/null 2>&1
  sudo chmod +x /usr/local/bin/jq
  /usr/local/bin/jq --version
fi

# create the keypair
api_result=$(curl "$rancher_url_local/$api_version/apikey" \
  -H 'content-type: application/json' \
  -H 'accept: application/json' \
  --data-binary '{"type":"apikey","accountId":"1a1","name":"RightScale-Global","description":"The global account API key for management by RightScale.","created":null,"kind":null,"removeTime":null,"removed":null,"uuid":null}' \
  --compressed)

# get the keypair
# might be useful for verification of db write
# api_result=$(curl "$rancher_url_local/$api_version/apikeys/$keypair_id" \
#  -H 'content-type: application/json' \
#  -H 'accept: application/json' \
#  --compressed)

# extract the key ID, public and secret values
keypair_id=$(echo "$api_result" | jq --raw-output '.id')
public_value=$(echo "$api_result" | jq --raw-output '.publicValue')
secret_value=$(echo "$api_result" | jq --raw-output '.secretValue')

echo '===='
echo "keypair ID: $keypair_id"
echo "public value: $public_value"
echo "secret value: <masked>"
echo '===='

# create RS credentials
# NOTE: this is not possible as rl10 proxy doesn't have observer, actor for credentials
#sudo /usr/local/bin/rsc \
#  --rl10 \
#  --dump=debug \
#  cm15 create credentials 'credential[name]=RANCHER_ACCESS_KEY-ACCOUNT' "credential[value]=$public_value"
#sudo /usr/local/bin/rsc \
#  --rl10 \
#  --dump=debug \
#  cm15 index credentials 'credential[name]=RANCHER_SECRET_KEY-ACCOUNT' "credential[value]=$secret_value"

# set tags with for the keypair
logger -s -t RightScale "Setting rancher:account_access_key tag"
sudo /usr/local/bin/rsc \
  --rl10 \
  --dump=debug \
  cm15 multi_add /api/tags/multi_add "resource_hrefs[]=$RS_SELF_HREF" "tags[]=rancher:account_access_key=$public_value"

logger -s -t RightScale "Setting rancher:account_secret_key tag"
sudo /usr/local/bin/rsc \
  --rl10 \
  --dump=debug \
  cm15 multi_add /api/tags/multi_add "resource_hrefs[]=$RS_SELF_HREF" "tags[]=rancher:account_secret_key=$secret_value"

echo 'Done.'
