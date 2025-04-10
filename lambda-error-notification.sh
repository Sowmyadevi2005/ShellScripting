#!/bin/bash

# ====================================================
# Author: Sowmyadevi Telidevara
# Version: 1.0
# Description: This script fetches recent AWS Lambda logs,
# scans for errors, and sends an SNS notification if any found.
# ====================================================

# ---------- CONFIGURATION ----------
LOG_GROUP_NAME="/aws/lambda/cost_optimazition"  #  Lambda log group
SNS_TOPIC_ARN="arn:aws:sns:us-east-1:515966510834:User-Access-Credentials"  # SNS topic ARN
REGION="us-east-1"
DURATION_MINUTES=60  # last 60 minutes
# -----------------------------------

# Calculate time range in milliseconds for CloudWatch filter
END_TIME=$(($(date +%s) * 1000))
START_TIME=$(($(date +%s -d "-$DURATION_MINUTES minutes") * 1000))

# ---------- FETCH LOGS ----------
ERROR_MESSAGES=$(aws logs filter-log-events \
    --log-group-name "$LOG_GROUP_NAME" \
    --start-time "$START_TIME" \
    --end-time "$END_TIME" \
    --filter-pattern '"ERROR"' \
    --query 'events[*].message' \
    --output text \
    --region "$REGION")

# ---------- HANDLE RESULTS ----------
if [[ -n "$ERROR_MESSAGES" ]]; then
    echo "Error(s) found in Lambda logs for the last $DURATION_MINUTES minutes."

    # Limit to first 10 lines for SNS (max 256 KB)
    ERROR_SUMMARY=$(echo "$ERROR_MESSAGES" | head -n 10)

    # Send SNS notification
    aws sns publish --topic-arn "$SNS_TOPIC_ARN" \
        --message "ALERT: Errors detected in Lambda logs for $LOG_GROUP_NAME in the last $DURATION_MINUTES minutes:\n\n$ERROR_SUMMARY" \
        --subject "Lambda Log Error Alert" \
        --region "$REGION"
fi
