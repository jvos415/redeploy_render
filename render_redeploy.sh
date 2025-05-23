#!/bin/bash

# First load in the environment variables from the .env file
set -a
source "$(dirname "$0")/.env"
set +a

delete_current_pg_instance() {
    # Ensure instance name is set
    if [ -z "$POSTGRES_INSTANCE_NAME" ]; then
        echo "POSTGRES_INSTANCE_NAME needs to be included in your .env file."
        exit 1
    fi

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
        return 0
    fi

    echo "Failed to delete postgres instance: $delete_response"
    exit 1
}

create_new_pg_instance() {
    # Ensure instance name is set
    if [ -z "$POSTGRES_INSTANCE_NAME" ]; then
        echo "POSTGRES_INSTANCE_NAME needs to be included in your .env file."
        exit 1
    fi

    # Ensure workspace id is set
    if [ -z "$RENDER_WORKSPACE_ID" ]; then
        echo "RENDER_WORKSPACE_ID needs to be included in your .env file."
        exit 1
    fi

    # Ensure postgres version is set
    if [ -z "$POSTGRES_VERSION" ]; then
        echo "POSTGRES_VERSION needs to be included in your .env file."
        exit 1
    fi

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
    return 0
}

verify_current_pg_instance_is_ready() {
    # Ensure instance name is set
    if [ -z "$POSTGRES_INSTANCE_NAME" ]; then
        echo "POSTGRES_INSTANCE_NAME needs to be included in your .env file."
        exit 1
    fi

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
            return 0
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

update_internal_db_url_for_services() {
    # Ensure instance name is set
    if [ -z "$POSTGRES_INSTANCE_NAME" ]; then
        echo "POSTGRES_INSTANCE_NAME needs to be included in your .env file."
        exit 1
    fi

    # Ensure database url key is set
    if [ -z "$RENDER_DATABASE_URL_KEY" ]; then
        echo "RENDER_DATABASE_URL_KEY needs to be included in your .env file."
        exit 1
    fi

    echo "Updating internal DB URLs for projects..."

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
        --url https://api.render.com/v1/postgres/$pg_instance_id/connection-info \
        --header "accept: application/json" \
        --header "authorization: Bearer $RENDER_API_KEY")

    # Check if the connection info response is empty
    if [ -z "$pg_connection_info_response" ]; then
        echo "No postgres instance connection info found."
        exit 1
    fi

    pg_internal_db_url=$(echo "$pg_connection_info_response" | jq -r '.internalConnectionString')
    echo "Internal DB url found."

    if [ -z $RENDER_SERVICE_IDS ]; then
        echo "RENDER_SERVICE_IDS have not been included in your .env file."
        echo "All render services will have their DATABASE_URL env var updated."

        get_services_response=$(curl --request GET \
            --url "https://api.render.com/v1/services?includePreviews=true&limit=20" \
            --header "accept: application/json" \
            --header "authorization: Bearer $RENDER_API_KEY")

        # Check if the response is empty
        if [ -z "$get_services_response" ]; then
            echo "No services found."
            exit 1
        fi

        # Check if the response is an empty array
        if echo "$get_services_response" | grep -q "^\[\]$"; then
            echo "No services found."
            exit 1
        fi

        service_ids=$(echo "$get_services_response" | jq -r '.[].service.id')

        for id in $service_ids; do
            echo
            echo "Updating internal db url for service: $id"

            # Update internal DB address
            service_env_var_put_response=$(curl --request PUT \
                --url https://api.render.com/v1/services/$id/env-vars/$RENDER_DATABASE_URL_KEY \
                --header "accept: application/json" \
                --header "authorization: Bearer $RENDER_API_KEY" \
                --header "content-type: application/json" \
                --data "{ \"value\": \"$pg_internal_db_url\" }")

            # Check if response contains an error message
            error_message=$(echo "$service_env_var_put_response" | jq -r '.message // empty')

            if [ -n "$error_message" ]; then
                echo "Failed to update environment variable: $error_message"
                exit 1
            fi

            echo "Internal db url updated, triggering redeploy..."

            # Clear cache and trigger redeploy
            curl --request POST \
                --url https://api.render.com/v1/services/$id/deploys \
                --header "accept: application/json" \
                --header "authorization: Bearer $RENDER_API_KEY" \
                --header "content-type: application/json" \
                --data '{ "clearCache": "clear" }'
        done
    else
        echo "Service ids found in env vars."
        echo "Updating internal DB vars for these services only."

        IFS=', ' read -r -a service_ids <<<"$RENDER_SERVICE_IDS"

        for service_id in "${service_ids[@]}"; do
            echo
            echo "Updating internal db url for service: $service_id"

            # Update internal DB address
            service_env_var_put_response=$(curl --request PUT \
                --url https://api.render.com/v1/services/$service_id/env-vars/$RENDER_DATABASE_URL_KEY \
                --header "accept: application/json" \
                --header "authorization: Bearer $RENDER_API_KEY" \
                --header "content-type: application/json" \
                --data "{ \"value\": \"$pg_internal_db_url\" }")

            # Check if response contains an error message
            error_message=$(echo "$service_env_var_put_response" | jq -r '.message // empty')

            if [ -n "$error_message" ]; then
                echo "Failed to update environment variable: $error_message"
                exit 1
            fi

            echo "Internal db url updated, triggering redeploy..."

            # Clear cache and trigger redeploy
            curl --request POST \
                --url https://api.render.com/v1/services/$service_id/deploys \
                --header "accept: application/json" \
                --header "authorization: Bearer $RENDER_API_KEY" \
                --header "content-type: application/json" \
                --data '{ "clearCache": "clear" }'
        done
    fi

    echo "Internal DB urls for services have been successfully updated and a redeploys have been triggered."
    return 0
}

# --- Help Menu --- #
usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -delete_db              Deletes current pg instance
  -create_db              Creates a new pg instance
  -verify_ready           Verifies that the current pg instance is ready (available)
  -update_db_urls         Updates all internal db urls for services from env var RENDER_SERVICES_IDS or, if RENDER_SERVICES_IDS is commented out, then automatically update internal db urls for all services
  -redeploy               Runs all above steps in order
  -h, --help              Show this help message
EOF
}

# --- Parse Arguments --- #
if [ $# -eq 0 ]; then
    usage
    exit 1
fi

while [[ "$1" != "" ]]; do
    case $1 in
    -delete_db) delete_current_pg_instance ;;
    -create_db) create_new_pg_instance ;;
    -verify_ready) verify_current_pg_instance_is_ready ;;
    -update_db_urls) update_internal_db_url_for_services ;;
    -redeploy)
        delete_current_pg_instance
        create_new_pg_instance
        verify_current_pg_instance_is_ready
        update_internal_db_url_for_services
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        usage
        exit 1
        ;;
    esac
    shift
done
