#!/usr/bin/env bash

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_PATH=$(dirname "${SCRIPT_PATH}")

SITES_DIR="${ROOT_PATH}/sites"

# Main function
main() {
    # Loop through each site directory under the sites directory
    for SITE_DIR in "$SITES_DIR"/*; do
    # Check if it's a directory
    if [ -d "$SITE_DIR" ]; then
        echo "Processing ${SITE_DIR}"
        # Running the find command to delete all except specified files/directories
        find "$SITE_DIR" -mindepth 1 | grep -vE "$SITE_DIR/(wp-content|\.env|wp-config.txt)" | while read -r line; do
            rm -rf "$line"
        done
        echo "Processed directory: $SITE_DIR"
    else
        echo "${SITE_DIR} is not a directory"
    fi
    done
}

# Execute main function
main

exit 0
