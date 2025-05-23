#!/bin/bash

for instance in $@
do
    INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance" "Name=instance-state-name,Values=running,stopped" --query "Reservations[*].Instances[*].InstanceId" --output text)

    if [ "$INSTANCE_ID" != "" ]
    then
        if [ $instance != "frontend" ]
        then
            IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
            RECORD_NAME=$instance.jayachandrarapolu.site
        else
            IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
            RECORD_NAME=jayachandrarapolu.site
        fi

        aws route53 change-resource-record-sets --hosted-zone-id Z06964512FQ47JZ19W0YM --change-batch '{
        "Comment": "Deleting DNS record for jayachandrarapolu.site",
        "Changes": [
            {
            "Action": "DELETE",
            "ResourceRecordSet": {
                "Name": "'$RECORD_NAME'",
                "Type": "A",
                "TTL": 1,
                "ResourceRecords": [
                {
                    "Value": "'$IP'"
                }
                ]
            }
            }
        ]
        }'

        aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
    else
        echo "Instance is not found with name $INSTANCE_NAME please check your instance name once again."
    fi
done