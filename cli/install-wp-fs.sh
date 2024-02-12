#!/usr/bin/env bash
set -euo pipefail

source cli/utils.sh

WORDPRESS_VERSION="${WORDPRESS_VERSION:-latest}"
WORDPRESS_SITE_PATH="${ROOT_PATH}/sites/${DOMAIN_NAME}"
# Use parameter expansion to set the variable
WORDPRESS_ZIP_FILE_NAME="${WORDPRESS_VERSION}"

if [ "$WORDPRESS_VERSION" != "latest" ]; then
    WORDPRESS_ZIP_FILE_NAME="wordpress-${WORDPRESS_LATEST_VERSION}"
fi

# Colors for output
GREEN="\033[32m"
YELLOW="\033[33m"
NORMAL="\033[0;39m"

# Download and unzip WordPress
# @TODO Cache specific versions and symlink to relevant sites
get_wordpress() {
    curl -s -L https://wordpress.org/$WORDPRESS_ZIP_FILE_NAME.zip -o "${WORDPRESS_SITE_PATH}/${WORDPRESS_ZIP_FILE_NAME}.zip"
    unzip -qq "${WORDPRESS_SITE_PATH}/${WORDPRESS_ZIP_FILE_NAME}.zip" -d "${WORDPRESS_SITE_PATH}"
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
        if [ -f "${WORDPRESS_SITE_PATH}/wp-config.txt" ]; then
            envsubst <"${WORDPRESS_SITE_PATH}/wp-config.txt" >"${WORDPRESS_SITE_PATH}/wp-config_temp.txt"
            sed -i '' "/\**#@-\*/r ${WORDPRESS_SITE_PATH}/wp-config_temp.txt" "${WORDPRESS_SITE_PATH}/wp-config_tmp.php"
            rm -rf "${WORDPRESS_SITE_PATH}/wp-config_temp.txt"
        fi
        mv "${WORDPRESS_SITE_PATH}/wp-config_tmp.php" "${WORDPRESS_SITE_PATH}/wp-config.php"
    else
        echo "  - ${YELLOW}wp-config-sample.php not found!${NORMAL}"
    fi
}

cleanup() {
    rm -rf "${WORDPRESS_SITE_PATH}/wordpress/" "${WORDPRESS_SITE_PATH}/${WORDPRESS_ZIP_FILE_NAME}.zip"
}

# Main function
main() {

    if test -f "${WORDPRESS_SITE_PATH}/wp-config.php"; then
        echo "${YELLOW}\nWordPress exists inside \"${WORDPRESS_SITE_PATH}\". Skipping install!\n${NORMAL}"
    else
        echo "\n🕐 Installing WordPress (${WORDPRESS_VERSION}), for ${DOMAIN_NAME}"
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
