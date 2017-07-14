#!/bin/bash -ex

# quit if server is not using elb
[ "$USING_ELB" != 'true' ] && \
  echo "Not load balanced, ELB deregistration not required, exiting." && exit 0

# get required metadata
instance_id=$(curl -Ss http://169.254.169.254/latest/meta-data/instance-id)
zone=$(curl -Ss http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${zone%?}

echo "deregistering $instance_id of $zone with '$ELB_NAME'"

aws elb deregister-instances-from-load-balancer \
  --region "$region" \
  --load-balancer-name "$ELB_NAME" \
  --instances "$instance_id"
