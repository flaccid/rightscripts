#! /bin/sh -e

: "${RANCHER_SERVER_ID:=default}"

. /var/run/rightlink/secret

# requires curl until deprecation by rsc
if ! type curl > /dev/null 2>&1; then
  echo 'Attempting to install curl brutally...'
  sudo apt-get -y install curl || sudo yum -y install curl
fi

logger -s -t RightScale "Setting rancher:server_id tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g \
  "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=rancher:server_id=$RANCHER_SERVER_ID"

echo 'Done.'
