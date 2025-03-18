#!/bin/bash

###############################################################################
# Author: Sowmyadevi Telidevara
# Version: v1.0.0
#
# Script to list various IAM resources in an AWS account.
#
# Below are the tasks performed by this script:
# 1. List all IAM users in the account.
# 2. List all IAM groups.
# 3. List all IAM roles.
# 4. List all IAM server certificates.
#
# This script uses AWS CLI to fetch the details and displays them in a table format.
#
# Usage: ./list_iam_resources.sh <resource_name>
# Example: ./list_iam_resources.sh users
#          ./list_iam_resources.sh users groups roles
###############################################################################

# Check if at least one resource name is provided
if [ $# -lt 1 ]; then
    echo "Usage: ./list_iam_resources.sh <resource_name>"
    echo "Example: ./list_iam_resources.sh users"
    exit 1
fi

# Loop through all input arguments to list IAM resources
for iam_resource in "$@"; do
    # Convert the resource name to lowercase (to handle case-insensitive input)
    iam_resource=$(echo "$iam_resource" | tr '[:upper:]' '[:lower:]')

    # Switch case to handle different AWS IAM resources
    case $iam_resource in
    users)
        echo "Fetching IAM Users..."
        aws iam list-users --query "Users[*].UserName" --output table
        ;;
    groups)
        echo "Fetching IAM Groups..."
        aws iam list-groups --query "Groups[*].GroupName" --output table
        ;;
    roles)
        echo "Fetching IAM Roles..."
        aws iam list-roles --query "Roles[*].RoleName" --output table
        ;;
    certificates)
        echo "Fetching IAM Server Certificates..."
        aws iam list-server-certificates --query "ServerCertificateMetadataList[*].ServerCertificateName" --output table
        ;;
    *)
        echo "Error: '$iam_resource' is not a valid IAM resource. Please use one of: users, groups, roles, certificates."
        ;;
    esac
done

# Completion message
echo "IAM Resources listed successfully."
