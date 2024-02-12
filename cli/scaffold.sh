#!/usr/bin/env bash

source cli/utils.sh
export $(grep -v '^#' "${ROOT_PATH}/.env" | xargs)

# Prompts
export DOMAIN_NAME=$(prompt_domain_name)
WORDPRESS_SITE_TITLE=$(prompt_inline_input "Site title")
IS_MULTISITE=$(prompt_inline_yn "Multisite")

NGINX_TEMPLATE_FILE="${NGINX_CONFIG_DIR}/nginx-site.conf.template"
WORDPRESS_URL="https://${DOMAIN_NAME}"
SITE_ID="${DOMAIN_NAME%%.*}"
ENV_FILE_CONTENTS="SITE_ID=${SITE_ID}
WORDPRESS_DB_NAME=${SITE_ID}_db
WORDPRESS_VERSION=${WORDPRESS_VERSION}
WORDPRESS_URL=${WORDPRESS_URL}
WORDPRESS_SITE_TITLE='${WORDPRESS_SITE_TITLE}'"

cp -r "${CONFIG_DIR}/site-scaffold" "${SITES_DIR}/${DOMAIN_NAME}"

if [[ "$IS_MULTISITE" == "y" ]]; then
    multisite_config="const MULTISITE = true;
const SUBDOMAIN_INSTALL = true;
const WP_HOME = '$WORDPRESS_URL';
const WP_SITEURL = '$WORDPRESS_URL';
"
    printf "${multisite_config}" >>"${SITES_DIR}/${DOMAIN_NAME}/wp-config.txt"
fi

echo "${ENV_FILE_CONTENTS}" >>"${SITES_DIR}/${DOMAIN_NAME}/.env"

export $(grep -v '^#' "${SITES_DIR}/${DOMAIN_NAME}/.env" | xargs)

envsubst '${DOMAIN_NAME}' <"$NGINX_TEMPLATE_FILE" >"${NGINX_CONFIG_DIR}/sites/${DOMAIN_NAME}.conf"

sh "${ROOT_PATH}/cli/certs.sh"

sh "${ROOT_PATH}/cli/install-wp-fs.sh"

if docker-compose ps | grep -q 'Up'; then
    echo "Docker-compose is running. Restarting services..."
    docker-compose restart nginx
    echo "Running WP CLI to install WordPress..."
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
            --url="${DOMAIN_NAME}" \
            --title="${WORDPRESS_SITE_TITLE}" \
            --admin_user="${WORDPRESS_ADMIN_USER}" \
            --admin_password="${WORDPRESS_ADMIN_PASSWORD}" \
            --admin_email="${WORDPRESS_ADMIN_EMAIL}" \
            --allow-root
    fi
else
    docker-compose up -d --build
fi
