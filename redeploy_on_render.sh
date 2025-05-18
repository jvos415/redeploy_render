#!/bin/bash

# First load in the environment variables from the .env file
set -a
source "$(dirname "$0")/.env"
set +a

delete_current_pg_instance() {
    # Get current postgres instance
    echo "Getting current pg instance..."
    pg_instance_response=$(curl --request GET \
        --url "https://api.render.com/v1/postgres?name=$POSTGRES_INSTANCE_NAME&includeReplicas=true&limit=20" \
        --header "accept: application/json" \
        --header "authorization: Bearer $RENDER_API_KEY")

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
        --header "authorization: Bearer $RENDER_API_KEY")

    if [ -z "$delete_response" ]; then
        echo "Postgres instance deleted successfully."
        exit 0
    fi

    echo "Failed to delete postgres instance: $delete_response"
    exit 1
}

create_new_pg_instance() {
    # Create new postgres instance (DB name from env var)
    echo "Creating new pg instance with the name '$POSTGRES_INSTANCE_NAME'..."

    create_response=$(
        curl --request POST \
            --url https://api.render.com/v1/postgres \
            --header "accept: application/json" \
            --header "authorization: Bearer $RENDER_API_KEY" \
            --header "content-type: application/json" \
            --data "{
                \"enableHighAvailability\": false,
                \"plan\": \"free\",
                \"name\": \"$POSTGRES_INSTANCE_NAME\",
                \"ownerId\": \"$RENDER_WORKSPACE_ID\",
                \"version\": \"$POSTGRES_VERSION\"
                }"
    )

    # Handle empty response
    if [ -z "$create_response" ]; then
        echo "Failed to create new postgres instance."
        exit 1
    fi

    # if the response has message then we know there was an error
    if echo "$create_response" | grep -q "message"; then
        echo "Error creating new postgres instance: $create_response"
        exit 1
    fi

    echo "New pg instance created successfully."
    exit 0
}

create_new_pg_instance

# wait??? or maybe employ a retry loop that try to fetch DB address

# go to each project and replace env var for internal DB address with newly fetched address

# wait???? maybe run a get request for each project and see if we get a 200 back?
