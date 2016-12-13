#! /bin/bash -e

: "${RANCHER_SERVER_IDENTIFIER:=default}"
: "${RANCHER_SERVER_ENDPOINT_HOST:=rancher.localdomain}"
: "${RANCHER_SERVER_PROTO:=http}"

. /var/run/rightlink/secret

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

echo 'Done.'
