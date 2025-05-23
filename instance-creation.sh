#!/bin/bash

# This script is used to launch the instances in aws and update the domain records.

IMAGE_ID="ami-09c813fb71547fc4f"
SG_ID="sg-0397920120499858a"
INSTANCE_NAME="$1"

#Inserting aws cli command to create instance
aws ec2 run-instances --image-id "$IMAGE_ID" --instance-type "t2.micro" --security-group-ids "$SG_ID" --tag-specifications "ResourceType="instance",Tags=[{Key="Name",Value="$1"}]"