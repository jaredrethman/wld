#!/usr/bin/env bash
set -euo pipefail

source "${WLD_DIR}/.env"

# Main function
main() {
    local domain_name="$1"
    local site_exists="$(site_exists $domain_name)"

    if [[ $site_exists -eq 0 ]]; then
        echo "\"${domain_name}\" not found! Run: 'wld scaffold'"
        return
    fi
    
    ARE_YOU_SURE=$(prompt_inline_yn "This cannot be undone. Are you sure?")

    if [[ "$ARE_YOU_SURE" != "y" ]]; then
        return
    fi

    source "${SITES_DIR}/${domain_name}/.env"
    
    rm -rf "${SITES_DIR}/${domain_name}" \
           "${CERTS_CONFIG_DIR}/${domain_name}.key" \
           "${CERTS_CONFIG_DIR}/${domain_name}.crt" \
           "${NGINX_CONFIG_DIR}/sites/${domain_name}.conf"

    docker-compose exec -T mariadb mysql --user="${MARIADB_USER}" --password="${MARIADB_PASSWORD}" <<-EOSQL
        DROP DATABASE \`${WORDPRESS_DB_NAME}\`;
EOSQL

}

# Execute main function
main "$@"

exit 0
