#!/bin/bash

echo "🐳 Starting LocalStack with Docker..."

# Stop any existing LocalStack containers
echo "🛑 Stopping existing LocalStack containers..."
docker stop localstack-main 2>/dev/null || true
docker rm localstack-main 2>/dev/null || true

# Start LocalStack with minimal configuration
echo "🚀 Starting LocalStack container..."
docker run -d \
  --name localstack-main \
  -p 4566:4566 \
  -e SERVICES=ec2,iam,sts \
  -e DEBUG=1 \
  -e LOCALSTACK_HOST=localhost \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -e AWS_ACCESS_KEY_ID=test \
  -e AWS_SECRET_ACCESS_KEY=test \
  localstack/localstack:latest

echo "⏳ Waiting for LocalStack to be ready..."
sleep 10

# Check if LocalStack is running
if curl -s http://localhost:4566/health > /dev/null 2>&1; then
    echo "✅ LocalStack is running successfully!"
    echo "📊 LocalStack health status:"
    curl -s http://localhost:4566/health
else
    echo "❌ LocalStack failed to start. Checking logs..."
    docker logs localstack-main
    exit 1
fi

echo ""
echo "🎉 LocalStack is ready for use!"
echo "🔗 LocalStack endpoint: http://localhost:4566"
