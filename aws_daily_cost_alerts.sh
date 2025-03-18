#!/bin/bash
# --------------------------------------------------------------------------------
# Script Name: aws_daily_cost_alert.sh
# Author: SowmyaDevi Telidevara
# Version: 1.0
# Description:
#   This script retrieves the estimated daily AWS cost from CloudWatch and
#   sends an alert via AWS SNS. The notification is published to an SNS topic,
#   which can have multiple subscribers (email, SMS, etc.).
# Note:
#   Before using this script, ensure you have:
#   1. Created an SNS topic using the following command:
#      aws sns create-topic --name AWS-Cost-Alerts
#   2. Subscribed to the topic (email/SMS) using(international SMS will be charged):
#      aws sns subscribe --topic-arn arn:aws:sns:us-east-1:XXXXXXXXXXXX:AWS-Cost-Alerts \
#                        --protocol email --notification-endpoint your-email@example.com
#      aws sns subscribe --topic-arn arn:aws:sns:us-east-1:XXXXXXXXXXXX:AWS-Cost-Alerts \
#                        --protocol sms --notification-endpoint +91XXXXXXXXXX
#--------------------------------------------------------------------------------

# Define the SNS Topic ARN where the cost alert will be sent
SNS_TOPIC_ARN="arn:aws:sns:us-east-1:515966510834:AWS-Cost-Alerts"

# Get Yesterday's Date
YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)

# --------------------------------------------------------------------------------
# Step 1: Retrieve Daily AWS Cost from CloudWatch
# --------------------------------------------------------------------------------
TOTAL_COST=$(aws cloudwatch get-metric-statistics \
    --namespace "AWS/Billing" \
    --metric-name "EstimatedCharges" \
    --dimensions Name=Currency,Value=USD \
    --start-time $(date -d 'yesterday' --iso-8601=seconds) \
    --end-time $(date --iso-8601=seconds) \
    --period 86400 \
    --statistics Maximum \
    --query "Datapoints[0].Maximum" \
    --output text)

# --------------------------------------------------------------------------------
# Step 2: Check IF Cost exists
# --------------------------------------------------------------------------------

if [[ -z "$TOTAL_COST" || "$TOTAL_COST" == "null" ]]; then
    TOTAL_COST="0.00"
fi

# --------------------------------------------------------------------------------
# Step 3: Publish the Cost Alert to SNS
# --------------------------------------------------------------------------------
aws sns publish --topic-arn "$SNS_TOPIC_ARN" \
    --message "AWS Daily Cost Alert: Total cost for $YESTERDAY is $TOTAL_COST USD."

exit 0
# --------------------------------------------------------------------------------
# End of Script
# --------------------------------------------------------------------------------
# ====================================================
# NOTE: How to Schedule This Script as a Cron Job
# ====================================================
#  For Linux/macOS:
# - Open crontab: crontab -e
# - Add the following line to run the script daily at 9 PM:
#   0 21 * * * /path/to/aws_daily_cost_alert.sh >> /var/log/aws_cost_alert.log 2>&1
# - Save and exit.

# For Windows (Using Task Scheduler):
# 1. Open Task Scheduler (Win + R → taskschd.msc → Enter).
# 2. Click "Create Basic Task" → Name it "AWS Cost Alert".
# 3. Choose "Daily" and set time to 9 PM.
# 4. Select "Start a Program" and use:
#    - Program/script: C:\Program Files\Git\bin\bash.exe
#    - Add arguments: -c "/path/to/aws_daily_cost_alert.sh"
# 5. Click "Finish" and enable the task.
# 6. Verify the task in Task Scheduler.
