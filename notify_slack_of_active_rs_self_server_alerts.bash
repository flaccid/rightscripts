#!/bin/bash -e

echo "Querying instance self..."
instance_href=$(sudo /usr/local/bin/rsc --rl10 cm15 --x1 ':has(.rel:val("self")).href' index_instance_session /api/sessions/instance)
server_href=$(sudo /usr/local/bin/rsc --rl10 --pp cm15 show --x1 ':has(.rel:val("parent")).href' "$instance_href")
cloud_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("cloud")).href')
datacenter_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("datacenter")).href')
alerts_href=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$instance_href" view=extended --x1 ':has(.rel:val("alerts")).href')
echo "cloud href:      $cloud_href"
echo "instance href:   $instance_href"
echo "server href:     $server_href"
echo "datacenter href: $datacenter_href"
echo "alerts href: $alerts_href"

# so we can get the rs host and account ID
eval $(sudo cat /var/lib/rightscale-identity)

fqdn=$(hostname -f)

# get all alerts of server instance
filter_status='triggered'
alerts=$(sudo /usr/local/bin/rsc --rl10 cm15 index "$alerts_href" "filter[]=status==$filter_status")

# if jq is not installed, lets install the linux binary
if ! type jq > /dev/null 2>&1; then
  echo 'Installing jq...'
  source /etc/profile.d/*proxy* > /dev/null 2>&1 || true
  curl -SsLk "https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64" | sudo tee /usr/local/bin/jq > /dev/null 2>&1
  sudo chmod +x /usr/local/bin/jq
  /usr/local/bin/jq --version
fi

echo 'Triggered alerts:'
echo '---'
echo "$alerts"
echo '---'

alert_msgs=()

# iterate over each alert
for alert_spec_href in $(echo "$alerts" | jq -r '.[] .links[] | select(.rel | contains("alert_spec")).href'); do
  # echo "$alert_spec"
  alert_spec=$(sudo /usr/local/bin/rsc --rl10 cm15 show "$alert_spec_href")
  name=$(echo "$alert_spec" | jq -r '.name')
  condition=$(echo "$alert_spec" | jq -r '.condition')
  description=$(echo "$alert_spec" | jq -r '.description')
  duration=$(echo "$alert_spec" | jq -r '.duration')
  escalation_name=$(echo "$alert_spec" | jq -r '.escalation_name')
  variable=$(echo "$alert_spec" | jq -r '.variable')
  threshold=$(echo "$alert_spec" | jq -r '.threshold')

  summary=$(echo "[$escalation_name/$name] is $condition $threshold for ${duration}mins")
  # echo "$summary"
  alert_msgs+=("$summary")
done

if [ "${#alert_msgs[@]}" -lt 1 ]; then
  echo 'No active alerts found, skipping.'
  exit 0
fi

server_link="http://${api_hostname}"$(echo $server_href | sed "s%api/%acct/$account/%g")

slack_message="<$server_link|${fqdn}> : ${alert_msgs[@]}"
echo "slack message:: {$slack_message}"

# notify slack
export no_proxy="$(echo $SLACK_ALERTS_WEBHOOK_URL | awk -F/ '{print $3}')"
data="{\"text\": \"$slack_message\", \"channel\": \"$SLACK_ALERTS_CHANNEL\", \"username\": \"$SLACK_ALERTS_USERNAME\", \"icon_emoji\": \"$SLACK_ALERTS_ICON_EMOJI\"}"

echo 'Notifying Slack via webhook...'
curl -v -X POST -H 'Content-type: application/json' --data "$data" "$SLACK_ALERTS_WEBHOOK_URL"

echo 'Done.'
