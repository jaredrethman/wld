# Start from the official nginx image
FROM nginx:latest

# Remove the default nginx configuration files
RUN rm -f /etc/nginx/conf.d/default.conf

# Copy the main nginx configuration file
COPY ./nginx.conf /etc/nginx/nginx.conf

# Copy the common configurations
COPY ./common /etc/nginx/common

# Copy the site-specific configurations
COPY ./sites /etc/nginx/conf.d/sites
