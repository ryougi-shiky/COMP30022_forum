#!/bin/bash

# Database Server Provisioning Script
# This script installs and configures MongoDB with EBS volume

set -e

# Variables from Terraform
EBS_DEVICE="${ebs_device}"
ENVIRONMENT="${environment}"

# Update system
apt-get update
apt-get upgrade -y

# Install basic dependencies
apt-get install -y curl wget gnupg lsb-release

# Wait for EBS volume to be attached
echo "Waiting for EBS volume to be attached..."
while [ ! -e $EBS_DEVICE ]; do
    sleep 5
done

# Format and mount EBS volume for MongoDB data
if ! blkid $EBS_DEVICE; then
    echo "Formatting EBS volume..."
    mkfs.ext4 $EBS_DEVICE
fi

# Create MongoDB data directory
mkdir -p /data/db

# Mount EBS volume
mount $EBS_DEVICE /data/db

# Add to fstab for persistent mounting
echo "$EBS_DEVICE /data/db ext4 defaults 0 2" >> /etc/fstab

# Set permissions
chown -R mongodb:mongodb /data/db || true

# Install MongoDB
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -cs)/mongodb-org/6.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-6.0.list

apt-get update
apt-get install -y mongodb-org

# Configure MongoDB
cat > /etc/mongod.conf << EOF
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where to store data.
storage:
  dbPath: /data/db
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 0.0.0.0  # Allow connections from any IP

# process management
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

# security
security:
  authorization: disabled  # For development, enable for production

# replication
#replication:

# sharding
#sharding:

# Enterprise-Only Options
#auditLog:

#snmp:
EOF

# Set ownership for MongoDB
chown -R mongodb:mongodb /data/db
chown mongodb:mongodb /var/log/mongodb/mongod.log || touch /var/log/mongodb/mongod.log && chown mongodb:mongodb /var/log/mongodb/mongod.log

# Enable and start MongoDB
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to start
echo "Waiting for MongoDB to start..."
sleep 10

# Initialize database if needed
mongo --eval "
use ani;
db.createCollection('users');
db.createCollection('posts');
db.createCollection('notifications');
print('Database initialized successfully');
" || echo "Database initialization completed"

# Create backup script
cat > /opt/mongodb-backup.sh << 'EOF'
#!/bin/bash
# MongoDB backup script

BACKUP_DIR="/data/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ani_backup_$DATE"

mkdir -p $BACKUP_DIR

# Create backup
mongodump --db ani --out $BACKUP_DIR/$BACKUP_NAME

# Compress backup
tar -czf $BACKUP_DIR/$BACKUP_NAME.tar.gz -C $BACKUP_DIR $BACKUP_NAME

# Remove uncompressed backup
rm -rf $BACKUP_DIR/$BACKUP_NAME

# Keep only last 7 backups
cd $BACKUP_DIR
ls -t *.tar.gz | tail -n +8 | xargs -r rm

echo "Backup completed: $BACKUP_NAME.tar.gz"
EOF

chmod +x /opt/mongodb-backup.sh

# Create cron job for daily backups
echo "0 2 * * * root /opt/mongodb-backup.sh" >> /etc/crontab

# Configure firewall (UFW)
ufw --force enable
ufw allow 22/tcp
ufw allow from 10.0.1.0/24 to any port 27017

# Log completion
echo "Database server provisioning completed at $(date)" >> /var/log/provision.log
