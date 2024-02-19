#!/bin/bash

# On Start Up - Create databases for each site that exists in ./sites
for site in /sites/*; do
    DB_NAME=$(basename "$site")
    ENV_FILE="${site}/.env"

    if [[ ! -f "${ENV_FILE}" ]]; then
        echo "Script does not exist: $script_name"
        continue
    fi

    export $(grep -v '^#' "${ENV_FILE}" | xargs)

    # Create the database if it doesn't exist
    mysql --user=${MARIADB_USER} --password=${MARIADB_PASSWORD} <<-EOSQL
        CREATE DATABASE IF NOT EXISTS \`${WORDPRESS_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
EOSQL
    echo "\"${DB_NAME}\" database created!"
    unset $(grep -v '^#' "${ENV_FILE}" | sed -E 's/(.*)=.*/\1/' | xargs)
done

# docker-compose exec -T mariadb mysql --user=wpadmin --password=password123! -e "CREATE DATABASE IF NOT EXISTS \`poop\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
