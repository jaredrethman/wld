ARG MARIADB_VERSION=10.2
FROM mariadb:${MARIADB_VERSION}

# Copy your initialization scripts into the Docker container
COPY ./initdb /docker-entrypoint-initdb.d
