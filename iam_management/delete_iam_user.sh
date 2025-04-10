#!/bin/bash
###############################################################################
# Author: Sowmyadevi Telidevara
# Version: v0.0.1
#
# Script to automate the process of deleting an existing IAM user when an
# employee leaves the company.
#
# Below are the tasks performed by this script:
#
# 1. Verify if the IAM username is provided as an argument.
# 2. Check if the specified IAM user exists.
# 3. Fetch and detach all attached managed policies of the user.
# 4. Fetch and delete all inline policies of the user.
# 5. Fetch and delete all access keys associated with the user.
# 6. Check if the user has console access and delete the login profile.
# 7. Fetch and remove the user from all associated IAM groups.
# 8. Delete the IAM user from AWS.
#
# The script requires the IAM username as an input argument.
#
# Usage: ./delete_iam_user.sh <IAM-USERNAME>
# Example: ./delete_iam_user.sh Udaya
###############################################################################

# Check if username is provided
if [ -z "$1" ]; then
  echo "Usage: ./file_name.sh <IAM-USERNAME>"
  echo "Example: ./delete_iam_user.sh Udaya"
  exit 1
fi

IAM_USER=$1
if aws iam get-user --user-name "$IAM_USER" &>/dev/null; then
  echo "Deleting IAM User: $IAM_USER"
else
  echo "User $IAM_USER doesnot exist."
  exist 1
fi

# Detach user policies

POLICIES=$(aws iam list-attached-user-policies --user-name "$IAM_USER" --query "AttachedPolicies[*].PolicyArn" --output text)
if [ -z "$POLICIES" ]; then
  echo "zero Policies attached to the user"
else
  echo "Detaching user policies..."
  for policy in $POLICIES; do
    aws iam detach-user-policy --user-name "$IAM_USER" --policy-arn "$policy"
  done
fi
# Remove inline policies
INLINE_POLICIES=$(aws iam list-user-policies --user-name "$IAM_USER" --query "PolicyNames[]" --output text)
if [ -z "$INLINE_POLICIES" ]; then
  echo "No Inine Policies attached to the user"
else
  echo "Deleting inline policies..."
  for policy in $INLINE_POLICIES; do
    aws iam delete-user-policy --user-name "$IAM_USER" --policy-name "$policy"
  done
fi

# Delete access keys
ACCESS_KEYS=$(aws iam list-access-keys --user-name "$IAM_USER" --query "AccessKeyMetadata[*].AccessKeyId" --output text)
if [ -z "$ACCESS_KEYS" ]; then
  echo "No access Keys Avaialble"
else
  echo "Deleting access keys..."
  for key in $ACCESS_KEYS; do
    aws iam delete-access-key --user-name "$IAM_USER" --access-key-id "$key"
  done
fi

#Check if User have console access
if aws iam get-login-profile --user-name "$IAM_USER" &>/dev/null; then
  # Delete login profile (Console access)
  echo "Deleting login profile..."
  aws iam delete-login-profile --user-name "$IAM_USER" 2>/dev/null
else
  echo "User $IAM_USER doesnot have console access."
fi

# Fetch the User Groups
GROUP_NAMES=$(aws iam list-groups-for-user --user-name "$IAM_USER" --query "Groups[*].GroupName" --output text)
if [ -z "$GROUP_NAMES" ]; then
  echo "User is not a member of any groups."
else
  #Remove user from groups
  for group in $GROUP_NAMES; do
    echo "Removing user from group: $group"
    aws iam remove-user-from-group --user-name "$IAM_USER" --group-name "$group" 2>/dev/null
  done
fi

# Finally, delete the user
echo "Deleting the IAM user..."
aws iam delete-user --user-name "$IAM_USER"
if [$? -eq 0]; then
  echo "IAM User $IAM_USER has been deleted successfully!"
else
  echo "Unable to delete IAM User $IAM_USER .Please retry"
fi
