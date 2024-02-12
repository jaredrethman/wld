#!/usr/bin/env bash

source cli/utils.sh

NGINX_CONFIG_DIR="./config/nginx/sites"
TEMPLATE_FILE="./config/nginx/nginx-site.conf.template"
# Get latest WordPress version

nginx_site_conf() {
    envsubst '${DOMAIN_NAME}' <"$TEMPLATE_FILE" >"${NGINX_CONFIG_DIR}/${DOMAIN_NAME}.conf"
}

install_wordpress_files() {
    sh "${ROOT_PATH}/cli/install-wp-fs.sh"
}

generate_certs() {
    sh "${ROOT_PATH}/cli/certs.sh"
}

# Main function
main() {
    echo "Script: ./cli/install.sh"
    # each_site_env nginx_site_conf
    each_site_env "install_wordpress_files"
}

# Execute main function
main

exit 0
