#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH=$(dirname "${SCRIPT_PATH}")

SITES_DIR="${ROOT_PATH}/sites"
NGINX_CONFIG_DIR="./config/nginx/sites"
TEMPLATE_FILE="./config/nginx/nginx-site.conf.template"

nginx_site_conf() {
    envsubst '${DOMAIN_NAME}' <"$TEMPLATE_FILE" >"${NGINX_CONFIG_DIR}/${DOMAIN_NAME}.conf"
}

install_wordpress_files() {
    sh "${ROOT_PATH}/cli/install.sh"
}

generate_certs() {
    sh "${ROOT_PATH}/cli/certs.sh"
}

# Main function
main() {
    for SITE_DIR in "${SITES_DIR}"/*; do
        if [ -d "${SITE_DIR}" ]; then
            # Set default .env vars as base for environment variables
            export $(grep -v '^#' "${ROOT_PATH}/.env" | xargs)
            export DOMAIN_NAME=$(basename "${SITE_DIR}")
            env_file="${SITES_DIR}/${DOMAIN_NAME}/.env"
            if [ -f "${env_file}" ]; then
                # Export site specific .env variables
                export $(grep -v '^#' "${env_file}" | xargs)

                # Certs
                # generate_certs
                # Nginx
                nginx_site_conf
                # Install WP files
                # install_wordpress_files

                # Unset site specific .env variables
                unset $(grep -v '^#' "${env_file}" | sed -E 's/(.*)=.*/\1/' | xargs)
            else
                echo "No .env file found for ${DOMAIN_NAME}."
            fi
            unset $(grep -v '^#' "${ROOT_PATH}/.env" | sed -E 's/(.*)=.*/\1/' | xargs)
            unset DOMAIN_NAME
        fi
    done
}

# Execute main function
main

exit 0
