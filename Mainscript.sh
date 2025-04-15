#!/bin/bash

set -x  # Print commands as they run
set -e  # Exit immediately if a command exits with a non-zero status

# Update package lists
sudo apt update

# Install Docker and Docker Compose
sudo apt-get install -y \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Install Nginx
sudo apt install -y nginx

# Enable Nginx to start on boot
sudo systemctl enable nginx

# Replace Nginx default config with reverse proxy to port 3000
sudo tee /etc/nginx/sites-available/default > /dev/null <<EOL
server {
    listen 80;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

# Restart Nginx to apply the changes
sudo systemctl restart nginx

# Create project folders
cd /home
sudo mkdir -p myReactApp/{frontend,server,infrastructure}
sudo chown -R $USER:$USER myReactApp

# Install git
sudo apt install -y git

# Clone repositories
cd myReactApp/server
git clone <YOUR_SERVER_REPO_URL> .

cd ../frontend
git clone <YOUR_FRONTEND_REPO_URL> .

cd ../infrastructure
git clone <YOUR_INFRASTRUCTURE_REPO_URL> .

# Install Kubernetes dependencies
# Install kubectl
sudo apt install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg \
  https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
  https://apt.kubernetes.io/ kubernetes-xenial main" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubectl
