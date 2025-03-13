#!/bin/bash
###############################################################################
# Author: Sowmyadevi Telidevara
# Version: v0.0.1
#
# Script to automate the process of creating a new IAM user when a new employee joins the company.
#
# Below are the tasks performed by this script:
# 1. Check if the user already exists:
#    - If the user exists, proceed to check for other access features.
#    - If the user does not exist, create a new IAM user with the provided username.
#
# 2. Check if the user already has AWS Management Console access:
#    - If the user has console access, proceed to check for other access features.
#    - If not, enable console access for the user with a temporary password.
#
# 3. Check if the user already has access keys for programmatic access:
#    - If access keys exist, proceed to check if the user is already added to the group.
#    - If not, generate new access keys and store them in a credentials file.
#
# 4. Check if the user is already a member of the specified IAM group:
#    - If the user is already in the group, skip this step.
#    - If not, add the user to the group.
#
# 5. Compose and send an email with the following details:
#    - Username
#    - Temporary password for console login
#    - Access keys (if applicable)
#
# The script requires the IAM username and email ID as input arguments.
#
# Usage: ./create_iam_user.sh <username> <email-id>
# Example: ./create_iam_user.sh Udaya tsowme@gmail.com
###############################################################################

# Check if the required number of arguments are passed
if [ $# -ne 2 ]; then
    echo "Usage: ./create_iam_user.sh <username> <Email-Id>"
    echo "Example: ./create_iam_user.sh Udaya tsowme@gmail.com"
    exit 1
fi

# Initialize Variables
USER_NAME=$1                                 # The IAM user to be created
REGION='us-east-1'                           # AWS Region (Not needed for IAM, but kept for consistency)
PASSWORD=$(openssl rand -base64 12)          # Generate a random 12-character password
GROUP_NAME='Devops'                          # IAM Group to which the user will be added
EMAIL_TO=$2                                  # Email ID of the user
EMAIL_FROM='sowmya.telidavara@gmail.com'     # Sender email address (SES must be verified)
FROM_ARN="arn:aws:ses:us-east-1:515966510834:identity/sowmya.telidavara@gmail.com"
mail_required=false                          # Flag to determine if an email should be sent

# Check if the user already exists
if aws iam get-user --user-name "$USER_NAME" &>/dev/null; then
    echo "User $USER_NAME already exists."
else
    # Create IAM user
    if aws iam create-user --user-name "$USER_NAME" &>/dev/null; then
        echo "IAM User $USER_NAME created successfully."
        mail_required=true
    else
        echo "Failed to create user $USER_NAME."
        exit 1
    fi
fi

# Check if console access already exists
if aws iam get-login-profile --user-name "$USER_NAME" &>/dev/null; then
    echo "User $USER_NAME already has console access."
else
    # Create login profile with password reset required
    if aws iam create-login-profile --user-name "$USER_NAME" --password "$PASSWORD" --password-reset-required &>/dev/null; then
        echo "Console Access enabled for $USER_NAME with temporary password."
        mail_required=true
    else
        echo "Failed to provide console access for user $USER_NAME."
        exit 1
    fi
fi

# Check if access keys exist for the user
access_keys=$(aws iam list-access-keys --user-name "$USER_NAME" --query 'AccessKeyMetadata[*].AccessKeyId' --output text 2>/dev/null)
if [ -z "$access_keys" ]; then
    # Create new access keys
    keys=$(aws iam create-access-key --user-name "$USER_NAME" --query 'AccessKey.[AccessKeyId, SecretAccessKey]' --output text)
    access_key_id=$(echo "$keys" | awk '{print $1}')
    secret_access_key=$(echo "$keys" | awk '{print $2}')

    if [ -n "$access_key_id" ]; then
        echo "New Access Key generated."
        mail_required=true
    fi
else
    echo "Access Keys already exist for User $USER_NAME."
fi

# Add user to the specified group
if aws iam get-group --group-name "$GROUP_NAME" --query "Users[?UserName=='$USER_NAME'].UserName" --output text 2>/dev/null | grep -q "$USER_NAME"; then
    echo "User $USER_NAME is already in the $GROUP_NAME group."
else
    if aws iam add-user-to-group --user-name "$USER_NAME" --group-name "$GROUP_NAME" &>/dev/null; then
        echo "User $USER_NAME added to group $GROUP_NAME."
        mail_required=true
    else
        echo "Failed to add user $USER_NAME to group $GROUP_NAME."
        exit 1
    fi
fi

# Send email if required
if [ "$mail_required" = true ]; then
    CREDENTIAL_FILE="$USER_NAME-credentials.txt"
    cat <<EOF >"$CREDENTIAL_FILE"
Console URL: https://$REGION.signin.aws.amazon.com/console
User Name: $USER_NAME
Temporary Password: $PASSWORD
Access Key ID: ${access_key_id:-"N/A"}
Secret Access Key: ${secret_access_key:-"N/A"}
EOF

    # Construct email body
    EMAIL_BODY=$(cat <<EOF
Hello $USER_NAME,

Here are your AWS IAM user credentials:

Console URL: https://$REGION.signin.aws.amazon.com/console
User Name: $USER_NAME
Temporary Password: $PASSWORD

Access Key ID: ${access_key_id:-"N/A"}
Secret Access Key: ${secret_access_key:-"N/A"}

Kindly reset your password after login.
EOF
    )

    # Send email using AWS SES
    aws ses send-email \
        --from "$EMAIL_FROM" \
        --destination "ToAddresses=[\"$EMAIL_TO\"]" \
        --message "Subject={Data='AWS Credentials for $USER_NAME'},Body={Text={Data='$EMAIL_BODY'}}" \
        --region "$REGION" &>/dev/null

    if [ $? -eq 0 ]; then
        echo "Email sent successfully to $EMAIL_TO."
    else
        echo "Failed to send email. Check AWS SES settings."
    fi
fi

echo "User $USER_NAME provisioning completed successfully."
