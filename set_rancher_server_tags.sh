#! /bin/bash -e

: "${RANCHER_SERVER_IDENTIFIER:=default}"
: "${RANCHER_SERVER_ENDPOINT_HOST:=rancher.localdomain}"
: "${RANCHER_SERVER_PROTO:=http}"
: "${RANCHER_SERVER_SET_ACCOUNT_KEYPAIR_TAG:=false}"

. /var/run/rightlink/secret

: ${RANCHER_HOST_PORT:=80}
: ${rancher_url_local:=http://localhost:$RANCHER_HOST_PORT}

# requires curl until deprecation by rsc
if ! type curl > /dev/null 2>&1; then
  echo 'Attempting to install curl brutally...'
  sudo apt-get -y install curl || sudo yum -y install curl
fi

logger -s -t RightScale "Setting rancher:server tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:server=true"

logger -s -t RightScale "Setting rancher:server_identifier tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:server_identifier=$RANCHER_SERVER_IDENTIFIER"

logger -s -t RightScale "Setting rancher:proto tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:proto=$RANCHER_SERVER_PROTO"

logger -s -t RightScale "Setting rancher:endpoint_host tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:endpoint_host=$RANCHER_SERVER_ENDPOINT_HOST"

logger -s -t RightScale "Setting rancher:api_version tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:api_version=$RANCHER_API_VERSION"

if [ "$RANCHER_SERVER_SET_ACCOUNT_KEYPAIR_TAG" = 'true' ]; then
  export no_proxy=127.0.0.1

  # if jq is not installed, lets install the linux binary
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
    echo "Successfully installed jq, printing version information..."
    /usr/local/bin/jq --version
  fi

  # create the keypair
  echo "Creating keypair by calling Rancher API"
  retry_count=0
  until [ "$retry_count" -ge "5" ]
  do
    set +e 2>/dev/null # Disable error checking to allow retries on curl
    api_result=$(curl "$rancher_url_local/$RANCHER_API_VERSION/apikey" \
      --connect-timeout 5 \
      --max-time 30 \
      --retry 10 \
      --retry-delay 0 \
      --retry-max-time 120 \
      -H 'content-type: application/json' \
      -H 'accept: application/json' \
      --data-binary '{"type":"apikey","accountId":"1a1","name":"RightScale-Global","description":"The global account API key for management by RightScale.","created":null,"kind":null,"removeTime":null,"removed":null,"uuid":null}' \
      --compressed )

    curl_result=$?
    set -e 2>/dev/null #Re-enable error checking

    if [ $curl_result ]; then
      echo "API call to rancher was successful"
      echo "API Result: '$api_result'"
      break
    else
      retry_count=$[$retry_count+1]
      echo "Curl failed, the rancher server might still be starting. This is retry #$retry_count. Sleeping for 60 seconds before trying again."
      sleep 60
    fi
  done


  # extract the key ID, public and secret values
  echo "Extracting keypair details"
  keypair_id=$(echo "$api_result" | jq --raw-output '.id')
  public_value=$(echo "$api_result" | jq --raw-output '.publicValue')
  secret_value=$(echo "$api_result" | jq --raw-output '.secretValue')

  echo '===='
  echo "keypair ID: $keypair_id"
  echo "public value: $public_value"
  echo "secret value: <masked>"
  echo '===='

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
fi

echo 'Done.'
