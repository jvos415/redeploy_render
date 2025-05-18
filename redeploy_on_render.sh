#!/bin/bash

# First load in the environment variables from the .env file
set -a
source "$(dirname "$0")/.env"
set +a

delete_pg_instance() {
    # Get current postgres instance
    echo "Getting current pg instance..."
    pg_instance_response=$(curl --request GET \
        --url "https://api.render.com/v1/postgres?name=$POSTGRES_INSTANCE_NAME&includeReplicas=true&limit=20" \
        --header "accept: application/json" \
        --header "authorization: Bearer $RENDER_REDEPLOY_KEY")

    # need to add error handling here to check if nothing came back and or if the response was unauthorized

    pg_instance_id=$(echo "$pg_instance_response" | jq -r '.[].postgres.id')

    echo "Current Postgres instance id: $pg_instance_id"

    # Delete current postgres instance
}

create_new_pg_instance() {
    # Create new postgres instance (DB name from env var)
    echo "Creating new pg instance..."
}

delete_pg_instance

# wait??? or maybe employ a retry loop that try to fetch DB address

# go to each project and replace env var for internal DB address with newly fetched address

# wait???? maybe run a get request for each project and see if we get a 200 back?
