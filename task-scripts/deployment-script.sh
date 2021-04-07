#!/bin/bash

# echo "Hello, world!"

# echo $JIRA_INSTANCE

git clone https://github.com/anmolonruby/concourse-test
cd concourse-test
git checkout -b main
commit_name=$(git log -1 --pretty=%B)
echo $commit_name
pattern='^[a-zA-Z]+-[0-9]+'
issue_key=''
if [[ $commit_name =~ $pattern ]]; then
        issue_key= echo "${BASH_REMATCH[0]}"
fi
echo $issue_key

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

response=$(curl --request POST "https://api.atlassian.com/jira/deployments/0.1/cloud/$cloud_id/bulk" \
--header "From: ${email_id:-leave-me-alone}" \
--header "Authorization: Bearer $access_token" \
--header 'Content-Type: application/json' \
--data-raw "{
  \"deployments\": [
    {
      \"deploymentSequenceNumber\": 23,
      \"updateSequenceNumber\": 1,
      \"associations\": [
        {
          \"associationType\": \"issueIdOrKeys\",
          \"values\": [
            \"$issue_key\"
          ]
        }
      ],
      \"displayName\": \"random name\",
      \"url\": \"http://example.com\",
      \"description\": \"Updating APIs to v2.9\",
      \"lastUpdated\": \"2021-03-02T23:29:23.000Z\",
      \"state\": \"successful\",
      \"pipeline\": {
        \"id\": \"gfhd12hj33fdy\",
        \"displayName\": \"pipeline name\",
        \"url\": \"http://example.com/pipeline/gfhd12hj33fdy\"
      },
      \"environment\": {
        \"id\": \"prod123\",
        \"displayName\": \"Production\",
        \"type\": \"production\"
      }
    }
  ]
}")

echo $response
echo "$BUILD_PIPELINE_NAME"