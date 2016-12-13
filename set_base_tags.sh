#! /bin/sh -e

. /var/run/rightlink/secret

# requires curl until deprecation by rsc
if ! type curl > /dev/null 2>&1; then
  echo 'Attempting to install curl brutally...'
  sudo apt-get -y install curl || sudo yum -y install curl
fi

fqdn=$(hostname -f)
logger -s -t RightScale "Setting node:hostname tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=node:hostname=$fqdn"

private_ip=$(ip route get 1 | awk '{print $NF;exit}')
logger -s -t RightScale "Setting node:private_ip tag"
no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=node:private_ip=$private_ip"

public_ip=$(curl -s http://icanhazip.com/ | tr -d '\r')
if expr "$public_ip" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null; then
  logger -s -t RightScale "Setting last_boot:public_ip tag"
  no_proxy=127.0.0.1 curl -sS -X POST -H X-RLL-Secret:$RS_RLL_SECRET -g "http://127.0.0.1:$RS_RLL_PORT/api/tags/multi_add?resource_hrefs[]=$RS_SELF_HREF&tags[]=node:public_ip=$public_ip"
else
  echo 'No valid public IP detected, skipping.'
  echo 'icanhazip returned:'
  echo "$public_ip"
fi

echo 'Done.'
