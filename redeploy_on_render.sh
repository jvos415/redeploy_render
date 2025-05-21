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

verify_current_pg_instance_is_ready() {
    echo "Verifying if the current pg instance is ready..."

    pg_instance_response=$(curl --request GET \
        --url "https://api.render.com/v1/postgres?name=$POSTGRES_INSTANCE_NAME&includeReplicas=true&limit=20" \
        --header "accept: application/json" \
        --header "authorization: Bearer $RENDER_API_KEY")

    # Check if the response is empty
    if [ -z "$pg_instance_response" ]; then
        echo "No postgres instance found."
        exit 1
    # Check for an empty array
    elif echo "$pg_instance_response" | grep -q "^\[\]$"; then
        echo "No postgres instance found."
        exit 1
    # Check if response is unauthorized
    elif echo "$pg_instance_response" | grep -q "Unauthorized"; then
        echo "Unauthorized access. Please check your API key."
        exit 1
    fi

    pg_instance_id=$(echo "$pg_instance_response" | jq -r '.[].postgres.id')
    echo "Postgres instance found."

    attempt=1
    max_attempts=10

    while [ $attempt -le $max_attempts ]; do
        echo 
        echo "Checking postgres instance status..."
        echo "Attempt $attempt of $max_attempts..."

        # Check if the instance status is ready (available)
        db_status_response=$(curl --request GET \
            --url https://api.render.com/v1/postgres/$pg_instance_id \
            --header "accept: application/json" \
            --header "authorization: Bearer $RENDER_API_KEY")

        db_status=$(echo "$db_status_response" | jq -r '.status')
        if [ "$db_status" == "available" ]; then
            echo "Postgres instance is ready."
            exit 0
        fi

        attempt=$((attempt + 1))
        if [ $attempt -le $max_attempts ]; then
            echo "Waiting for 7 seconds before retrying..."
            sleep 7
        else
            echo "Max attempts reached. Postgres instance is not ready."
            exit 1
        fi
    done
}

update_internal_db_url_for_projects() {
    # go to each project and replace env var for internal DB address with newly fetched address
    echo "Updating project internal DB address..."

    # Get postgres instance id
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

    # Get internal DB address
    pg_connection_info_response=$(curl --request GET \
        --url https://api.render.com/v1/postgres/$postgres_instance_id/connection-info \
        --header "accept: application/json" \
        --header "authorization: Bearer $RENDER_API_KEY")

    # Check if the connection info response is empty
    if [ -z "$pg_connection_info_response" ]; then
        echo "No postgres instance connection info found."
        exit 1
    fi

    pg_internal_db_url=$(echo "$pg_instance_response" | jq -r '.internalConnectionString')
    echo "Internal DB url found."

    echo "pg_internal_db_url: $pg_internal_db_url"

    # Loop through each project (get projects from env vars)
    # First get the project (probably need the project Id)
    # Update internal DB address
    # Clear build cache and redeploy
}

verify_project_is_ready() {
    # wait???? maybe run a get request for each project and see if we get a 200 back?
    echo "Verifying that the project is running..."

    # Send http request to website URL
    # If 200 response we are good
    # anything else we are not good
}

# delete_current_pg_instance
# create_new_pg_instance
verify_current_pg_instance_is_ready
