#! /bin/bash -e

# quit if server is not using elb
[ "$USING_ELB" != 'true' ] && \
  echo "Not load balanced, ELB registration not required, exiting." && exit 0

# get required metadata
instance_id=$(curl -Ss http://169.254.169.254/latest/meta-data/instance-id)
zone=$(curl -Ss http://169.254.169.254/latest/meta-data/placement/availability-zone)
region=${zone%?}

echo "registering $instance_id of $zone with '$ELB_NAME'"

# register the instance with the elb
aws elb register-instances-with-load-balancer \
  --region "$region" \
  --load-balancer-name "$ELB_NAME" \
  --instances "$instance_id"
