#!/bin/bash
# User Data Script for EC2 Instance Auto-Configuration

set -euo pipefail

# Update system packages
apt-get update
apt-get upgrade -y

# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Node.js and npm
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Install Nginx
apt-get install -y nginx

# Setup MongoDB data directory on additional EBS volume
mkdir -p ${mongodb_data_dir}
# Format and mount the additional EBS volume for MongoDB data
if [ ! -f /data/mongodb/.mounted ]; then
    mkfs.ext4 /dev/xvdf
    echo '/dev/xvdf ${mongodb_data_dir} ext4 defaults 0 0' >> /etc/fstab
    mount ${mongodb_data_dir}
    chown -R 999:999 ${mongodb_data_dir}  # MongoDB user in Docker
    touch ${mongodb_data_dir}/.mounted
fi

# Clone your application repository
cd /home/ubuntu
git clone https://github.com/ryougi-shiky/COMP30022-IT-Project.git app
cd app

# Use the existing local docker-compose configuration
# Copy and modify the existing docker-compose.local.yml for production
cp deploy/docker-compose.local.yml deploy/docker-compose.production.yml

# Update the production configuration
sed -i 's/NODE_ENV: "development"/NODE_ENV: "production"/' deploy/docker-compose.production.yml
sed -i 's/CORS_WHITELIST: "http:\/\/localhost:3000"/CORS_WHITELIST: "http:\/\/localhost,http:\/\/$(curl -s http:\/\/169.254.169.254\/latest\/meta-data\/public-ipv4)"/' deploy/docker-compose.production.yml

# Update MongoDB volume to use the EBS mount
sed -i 's/mongodb_data:\/data\/db/\/data\/mongodb:\/data\/db/' deploy/docker-compose.production.yml

# Add restart policies for production
sed -i '/depends_on:/a\    restart: unless-stopped' deploy/docker-compose.production.yml

# Build and start the application
docker-compose -f deploy/docker-compose.production.yml up -d --build

# Configure Nginx as reverse proxy (optional, for production setup)
cat > /etc/nginx/sites-available/ani-app << 'EOF'
server {
    listen 8080;
    server_name _;

    # Frontend
    location / {
        proxy_pass http://localhost;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:17000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/ani-app /etc/nginx/sites-enabled/
systemctl reload nginx

# Set ownership for ubuntu user
chown -R ubuntu:ubuntu /home/ubuntu/app

# Log deployment completion
echo "$(date): AniAni application deployment completed" >> /var/log/ani-deployment.log
