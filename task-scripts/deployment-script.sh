#!/bin/sh

# echo "Hello, world!"

# echo $JIRA_INSTANCE

cloud_id=$(\
  curl "${JIRA_INSTANCE}/_edge/tenant_info" | \
  jq --raw-output '.cloudId')

# echo $cloud_id

access_token=$(curl --request POST 'https://api.atlassian.com/oauth/token' \
--header 'Content-Type: application/json' \
--data-raw "{
    \"audience\": \"api.atlassian.com\", 
    \"grant_type\":\"client_credentials\",
    \"client_id\": \"$CLIENT_ID\",
    \"client_secret\": \"$CLIENT_SECRET\"
}" | jq --raw-output '.access_token')

# echo $access_token

timestamp=`date "+%Y-%m-%d_%H:%M:%SZ"`

curl --request POST "https://api.atlassian.com/jira/deployments/0.1/cloud/$cloud_id/bulk" \
--header "From: ${email_id:-leave-me-alone}" \
--header "Authorization: Bearer $access_token" \
--header 'Content-Type: application/json' \
--data-raw "{
  \"deployments\": [
    {
      \"deploymentSequenceNumber\": 21,
      \"updateSequenceNumber\": 1,
      \"associations\": [
        {
          \"associationType\": \"issueIdOrKeys\",
          \"values\": [
            \"TST-11\"
          ]
        }
      ],
      \"displayName\": \"${BUILD_NAME}\",
      \"url\": \"${ATC_EXTERNAL_URL}\",
      \"description\": \"${BUILD_JOB_NAME}\",
      \"lastUpdated\": $timestamp,
      \"state\": \"successful\",
      \"pipeline\": {
        \"id\": \"gfhd12hj33fdy\",
        \"displayName\": ${BUILD_PIPELINE_NAME},
        \"url\": \"http://example.com/pipeline/gfhd12hj33fdy\"
      },
      \"environment\": {
        \"id\": \"production\",
        \"displayName\": \"Production\",
        \"type\": \"production\"
      }
    }
  ]
}"