#! /bin/bash -e

: "${RANCHER_SERVER_IDENTIFIER:=default}"
: "${RANCHER_API_VERSION:=v1}"

. /var/run/rightlink/secret

# requires curl until deprecation by rsc
if ! type curl > /dev/null 2>&1; then
  echo 'Attempting to install curl brutally...'
  sudo apt-get -y install curl || sudo yum -y install curl
fi

logger -s -t RightScale "Setting rancher:host tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:host=true"

logger -s -t RightScale "Setting rancher:server_identifier tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:server_identifier=$RANCHER_SERVER_IDENTIFIER"

logger -s -t RightScale "Setting rancher:api_version tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:api_version=$RANCHER_API_VERSION"

echo 'Done.'
