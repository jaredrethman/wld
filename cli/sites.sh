#!/usr/bin/env bash
# set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH=$(dirname "${SCRIPT_PATH}")

SITES_DIR="${ROOT_PATH}/sites"
NGINX_CONFIG_DIR="./config/nginx/sites"
TEMPLATE_FILE="./config/nginx/nginx-site.conf.template"
frames=('-' '\' '|' '/')

reset_animation(){
    pid="$1"
    reset_txt="${2:-Done}"
    kill $pid
    wait $pid 2>/dev/null
    printf "\033[1A\033[K"
    printf "\r\033[K${reset_txt}\n"
}

loading_animation() {
    loading_txt="${1:-Loading}"
    while true; do
        printf "\033[1A\033[K"
        printf "%s\n" "- Loading."
        sleep 0.1
        printf "\033[1A\033[K"
        printf "%s\n" "\\ Loading.."
        sleep 0.1
        printf "\033[1A\033[K"
        printf "%s\n" "| Loading..."
        sleep 0.1
        printf "\033[1A\033[K"
        printf "%s\n" "/ Loading.."
        sleep 0.1
    done
}

# loading_animation &
# LOADING_PID=$!

# # Simulate some work with sleep
# sleep 5  # Replace this with your actual work

# reset_animation $LOADING_PID "Loading complete"

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
                # Export site .env
                export $(grep -v '^#' "${env_file}" | xargs)

                # Certs:
                # generate_certs
                # Nginx:
                # nginx_site_conf
                # Install WP files:
                # install_wordpress_files
                
                

                # Unset site .env
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
# main

exit 0
