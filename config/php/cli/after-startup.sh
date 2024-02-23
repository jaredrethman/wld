#!/bin/sh

php-fpm &

# Update hosts file to point to dockers internal host
# required for communication with services bound to the host's loopback interface
for SITE_DIR in "/var/www/html"/*; do
    domain_name=$(basename "${SITE_DIR}")
    echo "$(getent hosts host.docker.internal | awk '{ print $1 }') ${domain_name}" >> /etc/hosts
done

for file in "/wld/"*; do
    if [ "$file" = "/wld/after-startup.sh" ]; then
        continue
    fi
    if [ -f "$file" ] && [ -x "$file" ]; then
        echo "Executing $file..."
        "$file"
    else
        echo "Skipping $file, not executable or not a regular file."
    fi
done

echo "Entrypoint autoloader complete"

wait