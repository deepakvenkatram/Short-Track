# Use the official Nginx image from Docker Hub
FROM nginx:1.25-alpine

# Copy the custom nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the frontend static files
COPY index.html /usr/share/nginx/html/index.html
