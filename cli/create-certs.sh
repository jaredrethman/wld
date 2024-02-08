#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WP_PATH=$(dirname "$SCRIPT_PATH")

if [[ ! -f "${WP_PATH}/.env" ]]; then
  echo "\".env\" file not detected."; exit
fi

# Load .env
source "${WP_PATH}/.env"

CORE_DIR="${WP_PATH}/core"
CERTS_DIR="${WP_PATH}/config/nginx/certs"
DOMAIN_NAME="${DOMAIN_NAME:-localhost}"

# UNTESTED
if command -v mkcert &> /dev/null; then
    echo "mkcert detected. Installing CA, if doesn't exist"
    mkcert -install

    if [ ! -d "${CERTS_DIR}" ]; then
        mkdir -p "${CERTS_DIR}"
    fi

    echo "Generating SSL certificates for \"${DOMAIN_NAME}\" using mkcert."
    mkcert -key-file "${CERTS_DIR}/${DOMAIN_NAME}-key.pem" -cert-file "${CERTS_DIR}/${DOMAIN_NAME}.pem" "${DOMAIN_NAME}" "*.${DOMAIN_NAME}"
    echo "Certificates generated and trusted."
    exit 0
fi

# If NOT macOS EXIT
if [[ "${OSTYPE}" != "darwin"* ]]; then
    echo "Cert creation only available on macOS. Consider installing https://github.com/FiloSottile/mkcert."
    exit 0
fi

if [ ! -d "${CERTS_DIR}" ]; then
    mkdir -p "${CERTS_DIR}"
fi

echo "\nGenerating certs for '${DOMAIN_NAME} *.${DOMAIN_NAME}' using OpenSSL"

# Map DOMAIN_NAME to 127.0.0.1 + add to hosts file
echo "✏ Adding \"127.0.0.1 ${DOMAIN_NAME}\" entry on \"/etc/hosts\"."
grep -qxF '127.0.0.1 '${DOMAIN_NAME} /etc/hosts || echo "127.0.0.1 ${DOMAIN_NAME}" | sudo tee -a /etc/hosts

# Generate openssl.cnf file with proper SAN entries
cat > "${CERTS_DIR}/openssl.cnf" <<EOF
    [req]
    distinguished_name = req_distinguished_name
    req_extensions = v3_req
    prompt = no

    [req_distinguished_name]
    CN = ${DOMAIN_NAME}

    [v3_req]
    basicConstraints = CA:FALSE
    keyUsage = nonRepudiation, digitalSignature, keyEncipherment
    extendedKeyUsage = serverAuth
    subjectAltName = @alt_names

    [alt_names]
    DNS.1 = ${DOMAIN_NAME}
    DNS.2 = *.${DOMAIN_NAME}
EOF

# Generate self-signed certificates
openssl req \
    -newkey rsa:2048 \
    -x509 \
    -nodes \
    -keyout "${CERTS_DIR}/${DOMAIN_NAME}-key.pem" \
    -new \
    -out "${CERTS_DIR}/${DOMAIN_NAME}.pem" \
    -subj "/CN=${DOMAIN_NAME}" \
    -extensions v3_req \
    -config "${CERTS_DIR}/openssl.cnf" \
    -sha256 \
    -days 3650 2>/dev/null

rm -f "${CERTS_DIR}/openssl.cnf"

# Trust self-signed certificate
echo "✏ Adding certs to Keychain"
if [ $(security dump-keychain | grep "${DOMAIN_NAME}" | wc -l | awk '{print $1}') -gt 0 ]; then
    sudo security delete-certificate -c ${DOMAIN_NAME}
fi
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "${CERTS_DIR}/${DOMAIN_NAME}.pem"

exit 0