#!/usr/bin/env bash

source cli/utils.sh
export $(grep -v '^#' "${ROOT_PATH}/.env" | xargs)

export WORDPRESS_LATEST_VERSION="$(get_wp_latest_version)"
CAN_INSTALL='n'
ENV_FILE_CONTENTS=""
NGINX_TEMPLATE_FILE="${NGINX_CONFIG_DIR}/nginx-site.conf.template"

set_install_details() {
    ### Prompt - start
    DOMAIN_NAME=$(prompt_domain_name)
    # Override .env vars
    WORDPRESS_SITE_TITLE=$(prompt_inline_input "Site title")
    WORDPRESS_VERSION=$(prompt_inline_input "WordPress Version (default: ${WORDPRESS_LATEST_VERSION})" "${WORDPRESS_LATEST_VERSION}")
    WORDPRESS_ADMIN_USER=$(prompt_inline_input "Username (default: ${WORDPRESS_ADMIN_USER})" "${WORDPRESS_ADMIN_USER}")
    WORDPRESS_ADMIN_EMAIL=$(prompt_inline_input "Email (default: ${WORDPRESS_ADMIN_EMAIL})" "${WORDPRESS_ADMIN_EMAIL}")
    WORDPRESS_ADMIN_PASSWORD=$(prompt_inline_input "Password (default: ${WORDPRESS_ADMIN_PASSWORD})" "${WORDPRESS_ADMIN_PASSWORD}")
    IS_MULTISITE=$(prompt_inline_yn "Multisite (default: n)")
    ### Prompt - end
    printf "${CLEAR_PREV_LINE}${CLEAR_PREV_LINE}${CLEAR_PREV_LINE}${CLEAR_PREV_LINE}${CLEAR_PREV_LINE}${CLEAR_PREV_LINE}${CLEAR_PREV_LINE}"
    printf "\n${TEXT_COLOR_BLUE_BOLD}Install details:${TEXT_COLOR_RESET}\n"
    printf " · ${TEXT_COLOR_GRAY}Title:${TEXT_COLOR_RESET} %s\n" "${WORDPRESS_SITE_TITLE}"
    printf " · ${TEXT_COLOR_GRAY}Domain:${TEXT_COLOR_RESET} %s\n" "${DOMAIN_NAME}"
    printf " · ${TEXT_COLOR_GRAY}WP Version:${TEXT_COLOR_RESET} %s\n" "${WORDPRESS_VERSION}"
    printf " · ${TEXT_COLOR_GRAY}Multisite:${TEXT_COLOR_RESET} %s\n" "${IS_MULTISITE}"
    printf " · ${TEXT_COLOR_GRAY}User:${TEXT_COLOR_RESET} %s\n" "${WORDPRESS_ADMIN_USER}"
    printf " · ${TEXT_COLOR_GRAY}Email:${TEXT_COLOR_RESET} %s\n" "${WORDPRESS_ADMIN_EMAIL}"
    printf " · ${TEXT_COLOR_GRAY}Password:${TEXT_COLOR_RESET} %s\n\n" "${WORDPRESS_ADMIN_PASSWORD}"
    CAN_INSTALL=$(prompt_inline_yn "Continue with install")

    if [[ "$CAN_INSTALL" != "y" ]]; then
        set_install_details
    fi

    export DOMAIN_NAME
    WORDPRESS_URL="https://${DOMAIN_NAME}"
    SITE_ID="${DOMAIN_NAME%%.*}"
    ENV_FILE_CONTENTS="SITE_ID=${SITE_ID}
WORDPRESS_DB_NAME=${SITE_ID}_db
WORDPRESS_VERSION=${WORDPRESS_VERSION}
WORDPRESS_ADMIN_USER=${WORDPRESS_ADMIN_USER}
WORDPRESS_ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL}
WORDPRESS_ADMIN_PASSWORD=${WORDPRESS_ADMIN_PASSWORD}
WORDPRESS_URL=${WORDPRESS_URL}
WORDPRESS_SITE_TITLE='${WORDPRESS_SITE_TITLE}'"
}

clone_domain_files() {
    # Clone template
    cp -r "${CONFIG_DIR}/site-scaffold" "${SITES_DIR}/${DOMAIN_NAME}"
    # Add wp-config.txt if multisite
    if [[ "$IS_MULTISITE" == "y" ]]; then
        multisite_config="\nconst MULTISITE = true;\nconst SUBDOMAIN_INSTALL = true;\nconst WP_HOME = '$WORDPRESS_URL';\nconst WP_SITEURL = '$WORDPRESS_URL';\n"
        echo "${multisite_config}" >>"${SITES_DIR}/${DOMAIN_NAME}/wp-config.txt"
    fi
    # Create, fill and export (current process) site .env file
    echo "${ENV_FILE_CONTENTS}" >>"${SITES_DIR}/${DOMAIN_NAME}/.env"
    export $(grep -v '^#' "${SITES_DIR}/${DOMAIN_NAME}/.env" | xargs)
}

wpcli_install_site() {
    docker-compose exec -T mariadb mysql --user="${MARIADB_USER}" --password="${MARIADB_PASSWORD}" <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${WORDPRESS_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EOSQL
    if [[ "$IS_MULTISITE" == "y" ]]; then
        docker-compose exec php wp core multisite-install \
            --path="/var/www/html/${DOMAIN_NAME}" \
            --title="${WORDPRESS_SITE_TITLE}" \
            --admin_user="${WORDPRESS_ADMIN_USER}" \
            --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
            --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
            --allow-root
    else
        docker-compose exec php wp core install \
            --path="/var/www/html/${DOMAIN_NAME}" \
            --url="${WORDPRESS_URL}" \
            --title="${WORDPRESS_SITE_TITLE}" \
            --admin_user="${WORDPRESS_ADMIN_USER}" \
            --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
            --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
            --allow-root
    fi
}

main() {
    set_install_details
    clone_domain_files
    # Add nginx.conf for site
    envsubst '${DOMAIN_NAME}' <"$NGINX_TEMPLATE_FILE" >"${NGINX_CONFIG_DIR}/sites/${DOMAIN_NAME}.conf"
    # Add certs
    sh "${ROOT_PATH}/cli/certs.sh"
    # Download and configure WordPress file system
    sh "${ROOT_PATH}/cli/install-wp-fs.sh"
    # Sync site up with
    if docker-compose ps | grep -q 'Up'; then
        docker-compose restart nginx
    else
        docker-compose up -d --build
    fi
    while true; do
        if docker-compose exec -T mariadb mysqladmin --user="${MARIADB_USER}" --password="${MARIADB_PASSWORD}" ping &>/dev/null; then
            wpcli_install_site
            break
        else
            sleep 5
        fi
    done
}

main
exit 0
