#!/bin/bash

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH=$(dirname "${SCRIPT_PATH}")

# Define the directory containing your .env files
ENV_DIR="${ROOT_PATH}/env"
NGINX_CONFIG_DIR="./config/nginx/sites-available"
TEMPLATE_FILE="./config/nginx/nginx-site.conf.template"

# Ensure the output directory exists
mkdir -p "${NGINX_CONFIG_DIR}"

# Load default environment variables first
# if [ -f "${ENV_DIR}/default.env" ]; then
#     export $(grep -v '^#' "${ENV_DIR}/default.env" | xargs)
# fi

# Function to read and apply environment variables from a file
# apply_env() {
#     local env_file=$1
#     echo "Processing $env_file"
#     local tmp_env=$(mktemp)
#     if [ -f "$ENV_DIR/default.env" ]; then
#         cat "$ENV_DIR/default.env" >"$tmp_env"
#     fi
#     cat "$env_file" >>"$tmp_env"
#     while IFS='=' read -r key value || [[ -n "$key" ]]; do
#         [[ $key = \#* || $key = "" || ! $key == *\=* ]] && continue
#         echo "$key=$value"
#     done <"$tmp_env"
#     # Clean up the temporary file
#     rm "$tmp_env"
# }

nginx_for_env() {
    local domain_name=$1
    envsubst '${DOMAIN_NAME}' <"$TEMPLATE_FILE" >"${NGINX_CONFIG_DIR}/${DOMAIN_NAME}.conf"
}

# Main function
main() {
    # Loop through all .env files except for default.env
    find "${ENV_DIR}" -type f -name "*.env" ! -name "default.env" -exec basename {} .env ';' | while read domain_env; do

        DOMAIN_NAME="${domain_env}"

        # Reset the environment to default for each domain to ensure a clean state
        # unset $(grep -v '^#' "${ENV_DIR}/default.env" | sed -E 's/(.*)=.*/\1/' | xargs)

        if [ -f "${ENV_DIR}/default.env" ]; then
            export $(grep -v '^#' "${ENV_DIR}/default.env" | xargs)
        fi

        # Load site-specific environment variables, overriding above defaults defaults
        if [ -f "${ENV_DIR}/${domain_env}.env" ]; then
            export $(grep -v '^#' "${ENV_DIR}/${domain_env}.env" | xargs)
        fi

        # Configure site
        nginx_for_env "${domain_env}"

        # Reset .env
        unset $(grep -v '^#' "${ENV_DIR}/${domain_env}.env" | sed -E 's/(.*)=.*/\1/' | xargs)
    done
}

# Execute main function
main

exit 0
