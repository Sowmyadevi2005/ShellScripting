#!/bin/bash
###############################################################################
# Author: Sowmyadevi Telidevara
# Version: v0.0.1

# Script to automate the process of listing all the resources in an AWS account
#
# Below are the services that are supported by this script:
# 1. EC2
# 2. RDS
# 3. S3
# 4. CloudFront
# 5. VPC
# 6. IAM
# 7. Lambda
# 8. SNS
# 9. SQS
# 10. DynamoDB
# 11. VPC
# 12. EBS
#
# The script will prompt the user to enter the AWS region and the service for which the resources need to be listed.
#
# Usage: ./aws_resource_list.sh  <aws_region> <aws_service> <aws_service>
# Example: ./aws_resource_list.sh us-east-1 ec2 s3
#############################################################################

#Check if the required number of arguments are passed
if [ $# -lt 2 ]; then
    echo "Usage: ./aws_resource_list.sh  <aws_region> <aws_service> <aws_service>"
    echo "Example: ./aws_resource_list.sh us-east-1 ec2 s3"
    exit 1
fi

aws_region=$1
shift

# Check if the AWS CLI is installed
if ! command -v aws &>/dev/null; then
    echo "AWS CLI is not installed. Please install the AWS CLI and try again."
    exit 1
fi

#Check if the AWS CLI is configured
if [ ! -d ~/.aws ]; then
    echo "AWS CLI is not configured. Please configure the AWS CLI and try again."
    exit 1
fi

# Loop through all passed AWS resource names as arguments
for aws_resource_name in "$@"; do
    # Convert the aws_resource_name to lowercase in if any characters are in uppercase
    aws_resource_name=$(echo "$aws_resource_name" | tr '[:upper:]' '[:lower:]')
    # Switch case to handle different AWS resources
    case $aws_resource_name in
    s3)
        # List S3 buckets and extract bucket names using awk
        s3_list=$(aws s3 ls | awk '{print $3}')
        if [ -z "$s3_list" ]; then
            echo "No S3 Buckets Found in Region: $aws_region"
        else
            echo "Listing S3 Buckets in $aws_region"
            echo $s3_list | tr ' ' '\n' # Convert space-separated list into newline-separated list
        fi
        ;;
    ec2)
        # Describe EC2 instances and extract Instance IDs and States
        ec2_instance=$(aws ec2 describe-instances --region "$aws_region" --query 'Reservations[*].Instances[*].{Instance:InstanceId, State:State.Name}' --output text)
        if [ -z "$ec2_instance" ]; then
            echo "No EC2 Instances Found in Region: $aws_region"
        else
            echo "Listing EC2 Instances in $aws_region"
            echo $ec2_instance | tr ' ' '\n'
        fi
        ;;
    rds)
        # List RDS instances by their identifiers
        rds_instances=$(aws rds describe-db-instances --region "$aws_region" --query 'DBInstances[*].{DBInstances:DBInstanceIdentifier}' --output text)
        if [ -z "$rds_instances" ]; then
            echo "No RDS Instances Found in Region: $aws_region"
        else
            echo "Listing RDS Instances in $aws_region"
            echo $rds_instances | tr ' ' '\n'
        fi
        ;;
    vpc)
        # Describe VPCs with their ID, CIDR block, and default status
        vpc=$(aws ec2 describe-vpcs --region $aws_region --query 'Vpcs[*].[VpcId, CidrBlock, IsDefault]' --output table)
        if [ -z "$vpc" ]; then
            echo "No VPC resources Found in Region: $aws_region"
        else
            echo "Listing VPCs in $aws_region"
            echo "$vpc"
        fi
        ;;
    iam)
        # List IAM users by their usernames
        iam=$(aws iam list-users --query 'Users[*].UserName' --output text)
        if [ -z "$iam" ]; then
            echo "No Users Found"
        else
            echo "Listing IAM Users"
            echo $iam | tr ' ' '\n'
        fi
        ;;
    cloudwatch)
        # List CloudWatch alarms with their names, states, and metric names
        cloudwatch_alarms=$(aws cloudwatch describe-alarms --region $aws_region --query 'MetricAlarms[*].[AlarmName, StateValue, MetricName]' --output text)
        if [ -z "$cloudwatch_alarms" ]; then
            echo "No CloudWatch Alarms Found in Region: $aws_region"
        else
            echo "Listing CloudWatch Alarms in $aws_region"
            echo "$cloudwatch_alarms"
        fi
        ;;
    lambda)
        # List Lambda functions by their names
        lambda=$(aws lambda list-functions --region $aws_region --query Functions[*].FunctionName --output text)
        if [ -z "$lambda" ]; then
            echo "No Lambda Functions in Region: $aws_region"
        else
            echo "Listing Lambda Functions in $aws_region"
            echo $lambda | tr ' ' '\n'
        fi
        ;;
    sns)
        # List SNS topics by their ARN (missing query parameter corrected)
        sns=$(aws sns list-topics --region $aws_region --query 'Topics[*].TopicArn' --output text)
        if [ -z "$sns" ]; then
            echo "No SNS Topics Found in Region: $aws_region"
        else
            echo "Listing SNS Topics in $aws_region"
            echo $sns
        fi
        ;;
    sqs)
        # List SQS queues
        sqs=$(aws sqs list-queues --region $aws_region --output text)
        if [ -z "$sqs" ]; then
            echo "No SQS Queues Found in Region: $aws_region"
        else
            echo "Listing SQS Queues in $aws_region"
            echo $sqs
        fi
        ;;
    dynamodb)
        # List DynamoDB tables by their names
        dynamodb=$(aws dynamodb list-tables --region $aws_region --query "TableNames[]" --output text)
        if [ -z "$dynamodb" ]; then
            echo "No DynamoDB Tables Found in Region: $aws_region"
        else
            echo "Listing DynamoDB Tables in $aws_region"
            echo $dynamodb
        fi
        ;;
    ebs)
        # Describe EBS volumes with their ID, size, and state
        ebs_vol=$(aws ec2 describe-volumes --region $aws_region --query 'Volumes[*].[VolumeId, Size, State]' --output text)
        if [ -z "$ebs_vol" ]; then
            echo "No EBS Volumes Found in Region: $aws_region"
        else
            echo "Listing EBS Volumes in $aws_region"
            echo $ebs_vol
        fi
        ;;
    *)
        # Handle invalid AWS resource name
        echo "$aws_resource_name is not a valid AWS resource."
        ;;
    esac
done
