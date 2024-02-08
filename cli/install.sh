#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH=$(dirname "${SCRIPT_PATH}")

WORDPRESS_VERSION="${WORDPRESS_VERSION:-6.4.2}"
WORDPRESS_SITE_PATH="${ROOT_PATH}/sites/${DOMAIN_NAME}"

# Colors for output
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NORMAL="\033[0;39m"

# Download and unzip WordPress
# @TODO Cache specific versions and symlink to relevant sites
get_wordpress() {
    curl -s -L https://wordpress.org/wordpress-$WORDPRESS_VERSION.zip -o "${WORDPRESS_SITE_PATH}/wordpress-${WORDPRESS_VERSION}.zip"
    unzip -qq "${WORDPRESS_SITE_PATH}/wordpress-${WORDPRESS_VERSION}.zip" -d "${WORDPRESS_SITE_PATH}"
}

# Sync downloaded WordPress with version controlled `wp-content`
sync_wordpress() {
    rsync -av --quiet --exclude wp-content "${WORDPRESS_SITE_PATH}/wordpress/" "${WORDPRESS_SITE_PATH}"
}

# Create wp-config and populate db constants etc
configure_wp_config() {
    if test -f "${WORDPRESS_SITE_PATH}/wp-config-sample.php"; then

        cp "$WORDPRESS_SITE_PATH/wp-config-sample.php" "$WORDPRESS_SITE_PATH/wp-config_tmp.php"

        # Add db credentials
        sed -i '' "s/database_name_here/${WORDPRESS_DB_NAME}/g" "${WORDPRESS_SITE_PATH}/wp-config_tmp.php"
        sed -i '' "s/username_here/${WORDPRESS_DB_USER}/g" "${WORDPRESS_SITE_PATH}/wp-config_tmp.php"
        sed -i '' "s/password_here/${WORDPRESS_DB_PASSWORD}/g" "${WORDPRESS_SITE_PATH}/wp-config_tmp.php"
        sed -i '' "s/localhost/${WORDPRESS_DB_HOST}/g" "${WORDPRESS_SITE_PATH}/wp-config_tmp.php"

        # Add additional wp-config constants from ./wp-config.txt
        envsubst < "${WORDPRESS_SITE_PATH}/wp-config.txt" > "${WORDPRESS_SITE_PATH}/wp-config_temp.txt"
        sed -i '' "/\**#@-\*/r ${WORDPRESS_SITE_PATH}/wp-config_temp.txt" "${WORDPRESS_SITE_PATH}/wp-config_tmp.php"
        mv "${WORDPRESS_SITE_PATH}/wp-config_tmp.php" "${WORDPRESS_SITE_PATH}/wp-config.php"
        rm -rf "${WORDPRESS_SITE_PATH}/wp-config_temp.txt"
    else
        echo "  - ${YELLOW}wp-config-sample.php not found!${NORMAL}"
    fi
}

cleanup() {
    rm -rf "${WORDPRESS_SITE_PATH}/wordpress/" "${WORDPRESS_SITE_PATH}/wordpress-${WORDPRESS_VERSION}.zip"
}

# Main function
main() {
    
    if test -f "${WORDPRESS_SITE_PATH}/wp-config.php"; then
        echo "${YELLOW}\nWordPress exists. Skipping install!\n${NORMAL}"
    else
        echo "\n🕐 Installing WordPress (v${WORDPRESS_VERSION}), for ${DOMAIN_NAME}"
        get_wordpress
        echo "${GREEN}✔ Done!\n${NORMAL}"
        echo "🔄 Syncing WordPress file system..."
        sync_wordpress
        echo "${GREEN}✔ Done!\n${NORMAL}"
        echo "🔧 Setting up wp-config.php..."
        configure_wp_config
        echo "${GREEN}✔ Done!\n${NORMAL}"
        echo "🚿 Cleaning temp file system..."
        cleanup
        echo "${GREEN}✔ Done!\n${NORMAL}"
        echo "🚀 WordPress file system install and configured!\n"
    fi
}

# Execute main function
main

exit 0
