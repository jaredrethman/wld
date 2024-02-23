#!/usr/bin/env bash

source cli/utils.sh

nginx_site_conf() {
    envsubst '${DOMAIN_NAME}' <"$NGINX_TEMPLATE_FILE" >"${NGINX_CONFIG_DIR}/${DOMAIN_NAME}.conf"
}

install_wordpress_files() {
    sh "${WLD_DIR}/cli/install-wp-fs.sh"
}

generate_certs() {
    sh "${WLD_DIR}/cli/certs.sh"
}

main() {
    each_site_env "install_wordpress_files"
}

main

exit 0
