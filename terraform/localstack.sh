#!/bin/bash

# LocalStack management script

set -e

case "$1" in
    start)
        echo "🚀 Starting LocalStack..."
        docker-compose -f docker-compose.localstack.yml up -d
        echo "⏳ Waiting for LocalStack to be ready..."

        max_attempts=30
        attempt=1

        while [ $attempt -le $max_attempts ]; do
            if curl -s http://localhost:4566/health > /dev/null; then
                echo "✅ LocalStack is ready!"
                curl -s http://localhost:4566/health | jq '.' 2>/dev/null || curl -s http://localhost:4566/health
                break
            fi

            if [ $attempt -eq $max_attempts ]; then
                echo "❌ LocalStack failed to start"
                exit 1
            fi

            echo "   Attempt $attempt/$max_attempts..."
            sleep 3
            ((attempt++))
        done
        ;;

    stop)
        echo "🛑 Stopping LocalStack..."
        docker-compose -f docker-compose.localstack.yml down
        echo "✅ LocalStack stopped"
        ;;

    restart)
        echo "🔄 Restarting LocalStack..."
        docker-compose -f docker-compose.localstack.yml down
        docker-compose -f docker-compose.localstack.yml up -d
        echo "✅ LocalStack restarted"
        ;;

    status)
        echo "📊 LocalStack status:"
        if curl -s http://localhost:4566/health > /dev/null; then
            echo "✅ LocalStack is running"
            curl -s http://localhost:4566/health | jq '.' 2>/dev/null || curl -s http://localhost:4566/health
        else
            echo "❌ LocalStack is not running"
            exit 1
        fi
        ;;

    logs)
        echo "📋 LocalStack logs:"
        docker-compose -f docker-compose.localstack.yml logs -f localstack
        ;;

    clean)
        echo "🧹 Cleaning LocalStack data..."
        docker-compose -f docker-compose.localstack.yml down -v
        rm -rf ./localstack-data
        mkdir -p ./localstack-data
        echo "✅ LocalStack data cleaned"
        ;;

    web)
        echo "🌐 Starting LocalStack with Web UI..."
        docker-compose -f docker-compose.localstack.yml --profile web up -d
        echo "✅ LocalStack with Web UI started"
        echo "🌐 Access Web UI at: http://localhost:8080"
        ;;

    *)
        echo "LocalStack Management Script"
        echo ""
        echo "Usage: $0 {start|stop|restart|status|logs|clean|web}"
        echo ""
        echo "Commands:"
        echo "  start   - Start LocalStack container"
        echo "  stop    - Stop LocalStack container"
        echo "  restart - Restart LocalStack container"
        echo "  status  - Check LocalStack status"
        echo "  logs    - Show LocalStack logs"
        echo "  clean   - Clean LocalStack data and containers"
        echo "  web     - Start LocalStack with Web UI"
        echo ""
        exit 1
        ;;
esac
