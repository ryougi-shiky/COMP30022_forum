#!/bin/bash

# Web Server Provisioning Script
# This script installs and configures Nginx, Node.js, and React frontend

set -e

# Variables from Terraform
MONGODB_HOST="${mongodb_host}"
ENVIRONMENT="${environment}"

# Update system
apt-get update
apt-get upgrade -y

# Install basic dependencies
apt-get install -y curl wget git unzip software-properties-common

# Install Node.js 18.x
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt-get install -y nodejs

# Install Nginx
apt-get install -y nginx

# Install PM2 for process management
npm install -g pm2

# Create application directory
mkdir -p /opt/ani-app
cd /opt/ani-app

# Clone or copy application code (you'll need to modify this based on your deployment method)
# For now, we'll assume code is deployed via separate CI/CD pipeline
# git clone https://github.com/your-repo/COMP30022-IT-Project.git .

# Create backend configuration
mkdir -p /opt/ani-app/backend
cat > /opt/ani-app/backend/.env << EOF
MONGODB_URI=mongodb://$MONGODB_HOST:27017
MONGODB_NAME=ani
NODE_ENV=$ENVIRONMENT
PORT=17000
CORS_WHITELIST=http://localhost:3000,http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
EOF

# Configure Nginx
cat > /etc/nginx/sites-available/ani-app << EOF
server {
    listen 80;
    server_name _;

    # Serve React frontend
    location / {
        root /opt/ani-app/frontend/build;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy API requests to backend
    location /api/ {
        proxy_pass http://127.0.0.1:17000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://127.0.0.1:17000/health;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
    }
}
EOF

# Enable the site
ln -sf /etc/nginx/sites-available/ani-app /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test nginx configuration
nginx -t

# Create systemd service for backend
cat > /etc/systemd/system/ani-backend.service << EOF
[Unit]
Description=ANI App Backend
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/ani-app/backend
Environment=NODE_ENV=$ENVIRONMENT
EnvironmentFile=/opt/ani-app/backend/.env
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Create deployment script
cat > /opt/ani-app/deploy.sh << 'EOF'
#!/bin/bash
# Deployment script to be run when new code is available

set -e

cd /opt/ani-app

# Pull latest code (modify based on your deployment method)
# git pull origin main

# Install/update backend dependencies
if [ -f "backend/package.json" ]; then
    cd backend
    npm install --production
    cd ..
fi

# Build frontend
if [ -f "frontend/package.json" ]; then
    cd frontend
    npm install
    npm run build
    cd ..
fi

# Restart services
systemctl daemon-reload
systemctl restart ani-backend
systemctl restart nginx

echo "Deployment completed successfully!"
EOF

chmod +x /opt/ani-app/deploy.sh

# Set proper ownership
chown -R ubuntu:ubuntu /opt/ani-app

# Enable and start services
systemctl daemon-reload
systemctl enable ani-backend
systemctl enable nginx
systemctl start nginx

# Log completion
echo "Web server provisioning completed at $(date)" >> /var/log/provision.log
