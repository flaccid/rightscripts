#!/bin/bash -ex

# Quit if server is not using ELB
if [ "$USING_ELB" != "true" ];
then
    echo "Not load balanced, ELB de-registration not required, exiting."
    exit 0
fi

instance_id=`curl http://169.254.169.254/latest/meta-data/instance-id/`
echo ${instance_id}
aws elb deregister-instances-from-load-balancer --load-balancer-name $ELB_NAME --instances ${instance_id}
