# Start from the official nginx image
ARG NGINX_VERSION=stable-alpine
FROM nginx:${NGINX_VERSION}

# Copy the main nginx configuration file
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy the common configurations
COPY ./common /etc/nginx/common

# Copy the site-specific configurations
# COPY ./sites /etc/nginx/conf.d
