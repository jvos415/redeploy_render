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

    # Check if the response is empty
    if [ -z "$pg_instance_response" ]; then
        echo "No postgres instance found."
        exit 1
    fi

    # Check if the response is an empty array
    if echo "$pg_instance_response" | grep -q "^\[\]$"; then
        echo "No postgres instance found."
        exit 1
    fi

    # Check if response is unauthorized
    if echo "$pg_instance_response" | grep -q "Unauthorized"; then
        echo "Unauthorized access. Please check your API key."
        exit 1
    fi

    pg_instance_id=$(echo "$pg_instance_response" | jq -r '.[].postgres.id')
    echo "Postgres instance found."

    # Delete current postgres instance
    echo "Deleting current pg instance..."
    delete_response=$(curl --request DELETE \
        --url "https://api.render.com/v1/postgres/$pg_instance_id" \
        --header "accept: application/json" \
        --header "authorization: Bearer $RENDER_REDEPLOY_KEY")

    if [ -z "$delete_response" ]; then
        echo "Postgres instance deleted successfully."
        exit 0
    fi

    echo "Failed to delete postgres instance."
    exit 1
}

create_new_pg_instance() {
    # Create new postgres instance (DB name from env var)
    echo "Creating new pg instance..."
}

delete_pg_instance

# wait??? or maybe employ a retry loop that try to fetch DB address

# go to each project and replace env var for internal DB address with newly fetched address

# wait???? maybe run a get request for each project and see if we get a 200 back?
