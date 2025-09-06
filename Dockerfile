# Dockerfile - serve prebuilt build/ with nginx
FROM nginx:stable-alpine
LABEL maintainer="evanjali@example.com"

# Remove default nginx files
RUN rm -rf /usr/share/nginx/html/*

# Copy prebuilt React build folder
COPY build/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
