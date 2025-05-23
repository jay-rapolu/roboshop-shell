#!/bin/bash

# This script is used to launch the instances in aws and update the domain records.

IMAGE_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0397920120499858a"
INSTANCE_NAME="$1"
#Inserting aws cli command to create instance

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id "$IMAGE_ID" --instance-type "t2.micro" --security-group-ids "$SG_ID" --tag-specifications "ResourceType="instance",Tags=[{Key="Name",Value="$instance"}]" --query "Instances[0].InstanceId" --output text)

    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        RECORD_NAME=$instance.jayachandrarapolu.site
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME=jayachandrarapolu.site
    fi

    aws route53 change-resource-record-sets --hosted-zone-id Z06964512FQ47JZ19W0YM --change-batch '{
        "Comment": "Creating or updating records for jayachandrarapolu",
        "Changes": [{
            "Action": "UPSERT",
                "ResourceRecordSet":{
                    "Name":"'${RECORD_NAME}'",
                    "Type":"A",
                    "TTL": 1,
                    "ResourceRecords":[{"Value":"'${IP}'"}]
                }
            }]
    }'
done