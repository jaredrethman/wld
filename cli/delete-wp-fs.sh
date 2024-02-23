#!/usr/bin/env bash

SITES_DIR="${WLD_DIR}/sites"

# Main function
main() {
    # Loop through each site directory under the sites directory
    for SITE_DIR in "$SITES_DIR"/*; do
        # Check if it's a directory
        if [[ -d "$SITE_DIR" ]]; then
            # Delete files excluding wp-content, .env, wp-config.txt
            find "$SITE_DIR" -type f ! -path "$SITE_DIR/wp-content/*" ! -name ".env" ! -name ".gitignore" ! -name "wp-config.txt" -exec rm -f {} +
            rm -rf "${SITE_DIR}/wp-admin"
            rm -rf "${SITE_DIR}/wp-includes"
            echo "Deleted WordPress file system for \"$SITE_DIR\""
        else
            echo "${SITE_DIR} is not a directory"
        fi
    done
}

# Execute main function
main

exit 0
