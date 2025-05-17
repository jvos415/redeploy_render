#!/bin/bash

# First load in the environment variables from the .env file
set -a
source "$(dirname "$0")/.env"
set +a

# Get current postgres instance
pg_instance_response=$(curl --request GET \
    --url "https://api.render.com/v1/postgres?name=$POSTGRES_INSTANCE_NAME&includeReplicas=true&limit=20" \
    --header "accept: application/json" \
    --header "authorization: Bearer $RENDER_REDEPLOY_KEY")

echo "response: $response"

# delete current postgres instance
# create new postgres instance (DB name from env var)

# wait??? or maybe employ a retry loop that try to fetch DB address

# go to each project and replace env var for internal DB address with newly fetched address

# wait???? maybe run a get request for each project and see if we get a 200 back?
