#!/bin/bash

# LocalStack deployment script

set -e

# Check if LocalStack is running
if ! curl -s http://localhost:4566/health > /dev/null; then
    echo "❌ LocalStack is not running. Please start it with './localstack.sh start' first."
    exit 1
fi

echo "✅ LocalStack is running."

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/ani-app-key ]; then
    echo "🔑 Generating SSH key pair..."
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/ani-app-key -N ""
fi

# Create terraform.tfvars for LocalStack
cat > terraform.tfvars.local << EOF
# This file is auto-generated for LocalStack deployment
project_name = "ani-app-dev"
environment = "development"
aws_region = "us-east-1"

# LocalStack configuration
localstack_enabled = true

# Instance types
instance_type_app = "t3.micro"
instance_type_db = "t3.micro"

# EBS volume size
ebs_volume_size = 10

# SSH key
public_key = "$(cat ~/.ssh/ani-app-key.pub)"
EOF

echo "📝 Created terraform.tfvars.local for LocalStack"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Apply deployment to LocalStack
echo "🚀 Deploying infrastructure to LocalStack..."
terraform apply -var-file="terraform.tfvars.local" -auto-approve

echo "✅ Deployment completed!"
echo ""
echo "📊 Getting outputs..."
terraform output

echo ""
echo "🎉 LocalStack deployment successful!"
echo "💡 You can now test your infrastructure locally."
echo ""
echo "🔧 Useful commands:"
echo "   - Check LocalStack status: curl http://localhost:4566/health"
echo "   - View LocalStack logs: docker-compose -f docker-compose.localstack.yml logs -f"
echo "   - Stop LocalStack: docker-compose -f docker-compose.localstack.yml down"
echo "   - Access LocalStack Web UI: http://localhost:8080 (if enabled)"
