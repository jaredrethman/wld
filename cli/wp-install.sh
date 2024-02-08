#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_PATH=$(dirname "${SCRIPT_PATH}")

# Load .env
set -a
[ -f "${WP_PATH}/.env" ] && source "${WP_PATH}/.env"
set +a

WP_VER="${WP_VER:-6.4.2}"
WP_HTML_PATH="${WP_PATH}/html"
WP_CONFIG_PATH="${WP_PATH}/config"

# Colors for output
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
NORMAL="\033[0;39m"

# Download and unzip WordPress
get_wordpress() {
    curl -s -L https://wordpress.org/wordpress-$WP_VER.zip -o "${WP_HTML_PATH}/wordpress-${WP_VER}.zip"
    unzip -qq "${WP_HTML_PATH}/wordpress-${WP_VER}.zip" -d "${WP_HTML_PATH}"
}

# Sync downloaded WordPress with version controlled `wp-content`
sync_wordpress() {
    rsync -av --quiet --exclude wp-content "${WP_HTML_PATH}/wordpress/" "${WP_HTML_PATH}"
}

# Create wp-config and populate db constants etc
configure_wp_config() {
    if test -f "${WP_HTML_PATH}/wp-config-sample.php"; then

        cp "$WP_HTML_PATH/wp-config-sample.php" "$WP_HTML_PATH/wp-config_tmp.php"

        # Add db credentials
        sed -i '' "s/database_name_here/${WP_DB_NAME}/g" "${WP_HTML_PATH}/wp-config_tmp.php"
        sed -i '' "s/username_here/${WP_DB_USER}/g" "${WP_HTML_PATH}/wp-config_tmp.php"
        sed -i '' "s/password_here/${WP_DB_PASSWORD}/g" "${WP_HTML_PATH}/wp-config_tmp.php"
        sed -i '' "s/localhost/${WP_DB_HOST}/g" "${WP_HTML_PATH}/wp-config_tmp.php"

        # Add additional wp-config constants from ./wp-config.txt
        envsubst <"${WP_PATH}/wp-config.txt" >"${WP_PATH}/wp-config_temp.txt"
        sed -i '' "/\**#@-\*/r ${WP_PATH}/wp-config_temp.txt" "${WP_HTML_PATH}/wp-config_tmp.php"
        mv "${WP_HTML_PATH}/wp-config_tmp.php" "${WP_HTML_PATH}/wp-config.php"
        rm -rf "${WP_PATH}/wp-config_temp.txt"
    else
        echo "  - ${YELLOW}wp-config-sample.php not found!${NORMAL}"
    fi
}

cleanup() {
    rm -rf "${WP_HTML_PATH}/wordpress/" "${WP_HTML_PATH}/wordpress-${WP_VER}.zip"
}

# Main function
main() {
    if test -f "${WP_HTML_PATH}/wp-config.php"; then
        echo "${YELLOW}\nWordPress exists. Skipping install!\n${NORMAL}"
    else
        echo "\n🕐 Installing WordPress"
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
