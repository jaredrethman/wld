# Prompt the user for a local domain

source cli/utils.sh

DOMAIN_NAME=$(prompt_domain_name) 

cp -r "${CONFIG_DIR}/site-scaffold" "${SITES_DIR}/${DOMAIN_NAME}"