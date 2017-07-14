#!/bin/bash -e

# Quit if server is not using ELB
if [ "$USING_ELB" != "true" ];
then
    echo "Not load balanced, ELB registration not required, exitting."
    exit 0
fi

# Get Instance ID from metadata
instance_id=`curl http://169.254.169.254/latest/meta-data/instance-id/`
echo ${instance_id}

# Register with ELB
aws elb register-instances-with-load-balancer --load-balancer-name $ELB_NAME --instances ${instance_id}
