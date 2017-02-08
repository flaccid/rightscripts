#! /bin/bash -e

# adapted from http://willwarren.com/2014/07/03/roll-dynamic-dns-service-using-amazon-route53/

# ROUTE_53_AWS_ACCESS_KEY_ID        AWS Access Key ID (required)
# ROUTE_53_AWS_SECRET_ACCESS_KEY    AWS Secret Access Key (required)
# ROUTE_53_ZONE_ID         Route 53 Zone ID (required)
# ROUTE_53_RECORD_SET      The CNAME you want to update e.g. hello.example.com (required)
# ROUTE_53_RECORD_TTL      The Time-To-Live of this recordset
# ROUTE_53_RECORD_COMMENT  The record set comment
# ROUTE_53_RECORD_TYPE     Change to AAAA if using an IPv6 address
# IP_PROVIDER              Other options, http://ifconfig.me/ip https://wtfismyip.com/text
# ROUTE_53_UPDATE_RECORD   Needs to be 'true' to action update


# (optional) You might need to set your PATH variable at the top here
# depending on how you run this script
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#---------------------------------------------------------------------------------------------------------------------------
# Variables
#---------------------------------------------------------------------------------------------------------------------------

: "${ROUTE_53_RECORD_TTL:=300}"
: "${ROUTE_53_RECORD_COMMENT:=Auto updated @ $(date)}"
: "${ROUTE_53_RECORD_TYPE:=A}"
: "${ROUTE_53_RECORD_SET:=$(hostname -f)}"
: "${IP_PROVIDER:=https://icanhazip.com/}"
: "${ADDRESS_TYPE:=public}"

export AWS_ACCESS_KEY_ID="$ROUTE_53_AWS_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$ROUTE_53_AWS_SECRET_ACCESS_KEY"
export log_file=/var/log/route53-update.log
export ip_file=/var/spool/public_ip.txt
export NEW_IP_ADDRESS=""
export ip="invalid"

#---------------------------------------------------------------------------------------------------------------------------
# FUNCTIONS
#---------------------------------------------------------------------------------------------------------------------------

function check_update_requested
{
    if [ "$ROUTE_53_UPDATE_RECORD" != 'true' ]; then
    echo '$ROUTE_53_UPDATE_RECORD not set to true, skipping.'
    exit 0
    fi
}

function valid_ip()
{
    local  ip=$1
    local  stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}


function update_dns()
{
    # Get IP Address from parameter
    if [[ $# -eq 0 ]] ; then
        echo 'Please provide IP address'
        exit 0
    fi
        local ip_address="$1"
        echo "IP has changed to $ip" | sudo tee -a "$log_file"
        # Fill a temp file with valid JSON
        tmp_file=$(mktemp /tmp/temporary-file.XXXXXXXX)
        cat > ${tmp_file} << EOF
        {
        "Comment":"$ROUTE_53_RECORD_COMMENT",
        "Changes":[
            {
            "Action":"UPSERT",
            "ResourceRecordSet":{
                "ResourceRecords":[
                {
                    "Value":"$ip_address"
                }
                ],
                "Name":"$ROUTE_53_RECORD_SET",
                "Type":"$ROUTE_53_RECORD_TYPE",
                "TTL":$ROUTE_53_RECORD_TTL
            }
            }
        ]
        }
EOF

        echo "Registing IP, $ip_address."
        echo "AWS_ACCESS_KEY_ID        $AWS_ACCESS_KEY_ID"
        echo "AWS_SECRET_ACCESS_KEY    ****"
        echo "ROUTE_53_ZONE_ID         $ROUTE_53_ZONE_ID"
        echo "ROUTE_53_RECORD_SET      $ROUTE_53_RECORD_SET"
        echo "ROUTE_53_RECORD_TTL      $ROUTE_53_RECORD_TTL"
        echo "ROUTE_53_RECORD_COMMENT  $ROUTE_53_RECORD_COMMENT"
        echo "ROUTE_53_RECORD_TYPE     $ROUTE_53_RECORD_TYPE"
        echo '----------------------------------------------'
        cat "$tmp_file"
        echo '----------------------------------------------'

        # Update the Hosted Zone record
        echo "Updating record..."
        update_result="$(aws route53 change-resource-record-sets \
            --hosted-zone-id $ROUTE_53_ZONE_ID \
            --change-batch file://$tmp_file)" 2>&1 | sudo tee -a "$log_file"
        retval="${PIPESTATUS[0]}"

        # Clean up
        rm "$tmp_file"

        echo "$update_result"

        if [ "$retval" != 0 ]; then
            echo "DNS update failed!"
            exit 1
        else
        echo 'DNS update succeeded.'
        fi

    # All Done - cache the IP address for next time
    (echo "$ip_address" | sudo tee "$ip_file") &> /dev/null
    echo 'Done.'
}

function check_iam_creds()
{
    iam_url='http://169.254.169.254/latest/meta-data/iam/security-credentials/'
    return_code=`curl -silent -I ${iam_url} | head -n 1 | cut -d" " -f2`

    if [ "$return_code" = '200' ]; then
      echo "The server has IAM credentials, unsetting variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY."
      echo "The AWS SDK should pick up creds from the metadata."
      unset AWS_ACCESS_KEY_ID
      unset AWS_SECRET_ACCESS_KEY
    else
      echo "This server does not have any IAM credentials, will use user supplied creds."
    fi
}

function get_public_ip()
{
    # Get the external IP address
    local ip=`curl -sS $IP_PROVIDER`

    if ! valid_ip $ip; then
        echo "Invalid IP address: $ip" >> "$log_file"
        exit 1
    fi

   NEW_IP_ADDRESS="${ip}"
}

function get_private_ip()
{
    NEW_IP_ADDRESS=`ifconfig eth0| grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*'`
}

function get_ip()
{
    if [ "$ADDRESS_TYPE" == "public" ];
    then
        get_public_ip
    else
        get_private_ip
    fi
}

function exit_if_dns_same()
{
    current_ip=`dig +short $ROUTE_53_RECORD_SET`
    if [ "$current_ip" == "$NEW_IP_ADDRESS" ];
    then
        echo "Current IP Address for $ROUTE_53_RECORD_SET is already $NEW_IP_ADDRESS, no update needed, Exitting."
        exit 0
    else
        echo "Current IP is: $current_ip"
        echo "New IP should be:  $NEW_IP_ADDRESS"
        echo "DNS Update required."
    fi
}


#---------------------------------------------------------------------------------------------------------------------------
# MAIN
#---------------------------------------------------------------------------------------------------------------------------


check_update_requested
get_ip
exit_if_dns_same
check_iam_creds

update_dns "$NEW_IP_ADDRESS"
