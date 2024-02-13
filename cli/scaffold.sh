#!/usr/bin/env bash

source cli/utils.sh
export $(grep -v '^#' "${ROOT_PATH}/.env" | xargs)

export WORDPRESS_LATEST_VERSION="$(get_wp_latest_version)"
ENV_FILE_CONTENTS=""
IS_MULTISITE="n"
NGINX_TEMPLATE_FILE="${NGINX_CONFIG_DIR}/nginx-site.conf.template"

set_install_details() {
    local can_install="n"
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
    printf "\n${TEXT_COLOR_BLUE_BOLD}Install details:${TEXT_REST}\n"
    printf " · ${TEXT_COLOR_GRAY}Title:${TEXT_REST} %s\n" "${WORDPRESS_SITE_TITLE}"
    printf " · ${TEXT_COLOR_GRAY}Domain:${TEXT_REST} %s\n" "${DOMAIN_NAME}"
    printf " · ${TEXT_COLOR_GRAY}WP Version:${TEXT_REST} %s\n" "${WORDPRESS_VERSION}"
    printf " · ${TEXT_COLOR_GRAY}Multisite:${TEXT_REST} %s\n" "${IS_MULTISITE}"
    printf " · ${TEXT_COLOR_GRAY}User:${TEXT_REST} %s\n" "${WORDPRESS_ADMIN_USER}"
    printf " · ${TEXT_COLOR_GRAY}Email:${TEXT_REST} %s\n" "${WORDPRESS_ADMIN_EMAIL}"
    printf " · ${TEXT_COLOR_GRAY}Password:${TEXT_REST} %s\n\n" "${WORDPRESS_ADMIN_PASSWORD}"
    can_install=$(prompt_inline_yn "Continue with install")

    if [[ "$can_install" != "y" ]]; then
        set_install_details
    fi

    export DOMAIN_NAME
    WORDPRESS_URL="https://${DOMAIN_NAME}"
    SITE_ID="${DOMAIN_NAME%%.*}"
    ENV_FILE_CONTENTS="SITE_ID=${SITE_ID} \
                     \nWORDPRESS_DB_NAME=${SITE_ID}_db \
                     \nWORDPRESS_VERSION=${WORDPRESS_VERSION} \
                     \nWORDPRESS_ADMIN_USER=${WORDPRESS_ADMIN_USER} \
                     \nWORDPRESS_ADMIN_EMAIL=${WORDPRESS_ADMIN_EMAIL} \
                     \nWORDPRESS_ADMIN_PASSWORD=${WORDPRESS_ADMIN_PASSWORD} \
                     \nWORDPRESS_URL=${WORDPRESS_URL} \
                     \nWORDPRESS_SITE_TITLE='${WORDPRESS_SITE_TITLE}'"
}

clone_domain_files() {
    # Clone template
    cp -r "${CONFIG_DIR}/site-scaffold" "${SITES_DIR}/${DOMAIN_NAME}"
    # Add wp-config.txt if multisite
    if [[ "$IS_MULTISITE" == "y" ]]; then
        multisite_config="\nconst MULTISITE = true; \
                          \nconst SUBDOMAIN_INSTALL = true; \
                          \nconst WP_HOME = '$WORDPRESS_URL'; \
                          \nconst WP_SITEURL = '$WORDPRESS_URL';"
        echo -e "${multisite_config}" >>"${SITES_DIR}/${DOMAIN_NAME}/wp-config.txt"
    fi
    # Create, fill and export (current process) site .env file
    echo -e "${ENV_FILE_CONTENTS}" >>"${SITES_DIR}/${DOMAIN_NAME}/.env"
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
            --skip-email \
            --allow-root &>/dev/null;
    else
        docker-compose exec php wp core install \
            --path="/var/www/html/${DOMAIN_NAME}" \
            --url="${WORDPRESS_URL}" \
            --title="${WORDPRESS_SITE_TITLE}" \
            --admin_user="${WORDPRESS_ADMIN_USER}" \
            --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
            --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
            --skip-email \
            --allow-root &>/dev/null;
    fi
}

main() {
    set_install_details
    clone_domain_files
    # Add nginx.conf for site
    envsubst '${DOMAIN_NAME}' <"$NGINX_TEMPLATE_FILE" >"${NGINX_CONFIG_DIR}/sites/${DOMAIN_NAME}.conf"
    # Add certs
    sh "${ROOT_PATH}/cli/certs.sh" &>/dev/null;
    # Download and configure WordPress file system
    sh "${ROOT_PATH}/cli/install-wp-fs.sh" &>/dev/null;
    # Sync site up with
    if docker-compose ps | grep -q 'Up'; then
        docker-compose restart nginx &>/dev/null;
    else
        docker-compose up -d --build &>/dev/null;
    fi
    while true; do
        if docker-compose exec -T mariadb mysqladmin --user="${MARIADB_USER}" --password="${MARIADB_PASSWORD}" ping &>/dev/null; then
            wpcli_install_site
            break
        else
            sleep 5
        fi
    done
    echo "Site created, visit: ${WORDPRESS_URL}/wp-admin"
}

main
exit 0
