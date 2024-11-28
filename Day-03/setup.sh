#!/bin/bash
set -xe

# starting grafana and jenkins images
echo "Starting Grafana and Jenkins docker images...."
docker run -d --name=grafana -p 3000:3000 grafana/grafana
docker run -d --name=jenkins -p 8080:8080 jenkins


# Installing Nginx
echo "Installing Nginx..."
command -v nginx >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Nginx is already installed."
else
    sudo apt-get update -y
    sudo apt-get install nginx -y
fi

# Creating Nginx configuration for Jenkins reverse proxy and TLS configuration
echo "Creating jenkins.conf file for the reverse proxy, TLS configuration, securing Jenkins, validating Jenkins, and restricting IP addresses..."

cat << EOF > /etc/nginx/conf.d/jenkins.conf
upstream jenkins {
    server localhost:8080;
}

server {
    listen 443 ssl;
    ssl on;
    ssl_certificate /etc/nginx/ssl/jenkins.crt;
    ssl_certificate_key /etc/nginx/ssl/jenkins.key;
    server_name jenkins.local.com;

    auth_basic "Site under maintenance";
    auth_basic_user_file /etc/nginx/conf/htpasswd;

    location / {
        proxy_pass http://jenkins;
        # Allow office CIDR block
        # allow 192.168.2.1/24;
        # deny all;
    }
}

server {
    if (\$host = jenkins.local.com) {
        return 301 https://\$host\$request_uri;
    }
    listen 80;
    server_name jenkins.local.com;
    return 404;
}
EOF

# Creating Nginx configuration for Grafana reverse proxy and TLS configuration
echo "Creating grafana.conf file for the reverse proxy and TLS configuration..."

cat << EOF > /etc/nginx/conf.d/grafana.conf
upstream grafana {
    server localhost:3000;
}

server {
    listen 443 ssl;
    ssl on;
    server_name grafana.local.com;
    ssl_certificate /etc/nginx/ssl/grafana.crt;
    ssl_certificate_key /etc/nginx/ssl/grafana.key;

    location / {
        proxy_pass http://grafana;
    }
}

server {
    if (\$host = grafana.local.com) {
        return 301 https://\$host\$request_uri;
    }
    listen 80;
    server_name grafana.local.com;
    return 404;
}
EOF

# Creating necessary directories for SSL certificates and password file
echo "Creating directories for SSL certificates and password file..."
mkdir -p /etc/nginx/ssl
mkdir -p /etc/nginx/conf

# Generating SSL certificates for Grafana and Jenkins
echo "Generating SSL certificates for Grafana and Jenkins..."
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/grafana.key -out /etc/nginx/ssl/grafana.crt -subj "/CN=grafana.local.com"
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/jenkins.key -out /etc/nginx/ssl/jenkins.crt -subj "/CN=jenkins.local.com"

# Generating password for Jenkins authentication
echo "Generating password for Jenkins authentication..."
read -sp "Enter the password for Jenkins authentication: " user_password
echo
hashed_password=$(openssl passwd -apr1 "$user_password")
echo "Generated APR1 hashed password: $hashed_password"
echo "admin:$hashed_password" > /etc/nginx/conf/htpasswd

# Copying the Jenkins and Grafana configuration files into /etc/nginx/conf.d
echo "Copying the Jenkins and Grafana configuration files into /etc/nginx/conf.d..."
cp /etc/nginx/conf.d/jenkins.conf /etc/nginx/conf.d/grafana.conf

# Restarting Nginx to apply the changes
echo "Restarting Nginx to apply the configurations..."
sudo systemctl restart nginx

echo "Script completed successfully!"
