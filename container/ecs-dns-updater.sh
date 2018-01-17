#!/bin/bash

set -e
set -x

region=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone/ | sed 's/.$//')
instance_arn=$(python -c 'import json, os; print(json.loads(open(os.environ.get("ECS_CONTAINER_METADATA_FILE")).read())["ContainerInstanceARN"])')
cluster=$(python -c 'import json, os; print(json.loads(open(os.environ.get("ECS_CONTAINER_METADATA_FILE")).read())["Cluster"])')
instance_id=$(aws ecs describe-container-instances --region $region --container-instance $instance_arn --cluster $cluster --query 'containerInstances[].ec2InstanceId' --output text)
instance_ip=$(aws ec2 describe-instances --region $region --instance-id=$instance_id --query 'Reservations[].Instances[].PrivateIpAddress' --output text)

function dns_update {
  DNS_HOST=$1
  INSTANCE_IP=$2

  cat << EOT
  {
    "Comment": "Updated by ecs-dns-updater at $(date)",
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "$DNS_HOST.$DNS_ZONE",
          "Type": "A",
          "TTL": 60,
          "ResourceRecords": [
            {
              "Value": "$INSTANCE_IP"
            }
          ]
        }
      }
    ]
  }
EOT
}

hosted_zone=$(aws route53 list-hosted-zones-by-name --region $region --dns-name $DNS_ZONE --max-items 1 --query 'HostedZones[].Id' --output text)

aws route53 change-resource-record-sets --region $region --hosted-zone-id=$hosted_zone --change-batch "$(dns_update $DNS_HOST $instance_ip)"
