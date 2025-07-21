#!/bin/bash

# AWS production deployment script

set -e

echo "🚀 Starting AWS deployment..."

# Check if AWS CLI is configured
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ AWS CLI is not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ AWS CLI is configured"

# Generate SSH key if it doesn't exist
if [ ! -f ~/.ssh/ani-app-aws-key ]; then
    echo "🔑 Generating SSH key pair for AWS..."
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/ani-app-aws-key -N ""
    echo "📤 Don't forget to add the public key to your AWS account if needed"
fi

# Create terraform.tfvars for AWS
cat > terraform.tfvars << EOF
project_name = "ani-app-prod"
environment = "production"
aws_region = "us-east-1"

# AWS configuration
localstack_enabled = false

# Instance types
instance_type_app = "t3.small"
instance_type_db = "t3.micro"

# EBS volume size
ebs_volume_size = 20

# SSH key
public_key = "$(cat ~/.ssh/ani-app-aws-key.pub)"
EOF

echo "📝 Created terraform.tfvars for AWS"

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan

# Confirm before applying
read -p "🤔 Do you want to proceed with the AWS deployment? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deploying to AWS..."
    terraform apply

    echo "✅ Deployment completed!"
    echo ""
    echo "📊 Getting outputs..."
    terraform output

    echo ""
    echo "🎉 AWS deployment successful!"
    echo "💡 Your application should be accessible at the URL shown above."
else
    echo "❌ Deployment cancelled."
fi
