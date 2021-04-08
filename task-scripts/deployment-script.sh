#!/bin/bash

# echo "Hello, world!"

# echo $JIRA_INSTANCE

pwd
ls -la

url=$(cat metadata/atc_external_url)
team=$(cat metadata/build_team_name)
pipeline=$(cat metadata/build_pipeline_name)
job=$(cat metadata/build_job_name)
build=$(cat metadata/build_name)
pipeline_url="$url/teams/$team/pipelines/$pipeline/jobs/$job/builds/$build"

git clone https://github.com/anmolonruby/concourse-test
cd concourse-test
git checkout -b main
commit_name=$(git log -1 --pretty=%B)
echo "$commit_name"
pattern='^[a-zA-Z]+-[0-9]+'
issue_key=''
if [[ $commit_name =~ $pattern ]]; then
        issue_key= echo "${BASH_REMATCH[0]}"
fi
echo "$issue_key"

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
      \"deploymentSequenceNumber\": $build,
      \"updateSequenceNumber\": 1,
      \"associations\": [
        {
          \"associationType\": \"issueIdOrKeys\",
          \"values\": [
            \"$issue_key\"
          ]
        }
      ],
      \"displayName\": \"$job\",
      \"url\": \"$url/teams/$team/pipelines/$pipeline/jobs/$job\",
      \"description\": \"Updating APIs to v2.9\",
      \"lastUpdated\": \"2021-03-02T23:29:23.000Z\",
      \"state\": \"successful\",
      \"pipeline\": {
        \"id\": \"$pipeline\",
        \"displayName\": \"$pipeline\",
        \"url\": \"$pipeline_url\"
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