#!/bin/bash
# 方案一手动启动指南

echo "=================== 🚀 方案一：EC2 + Elastic IP架构 ==================="
echo ""
echo "📋 架构说明："
echo "   - 单实例部署（模拟EC2实例）"
echo "   - 免费网络暴露（模拟Elastic IP）"
echo "   - 容器化应用栈"
echo "   - 最经济方案：约15美元/月"
echo ""

echo "🔧 手动启动步骤："
echo ""
echo "1. 确保Docker服务正在运行："
echo "   sudo systemctl start docker    # Linux"
echo "   # 或者在macOS上启动Docker Desktop"
echo ""

echo "2. 启动应用服务："
echo "   cd /Users/shikiryougi/ryougi-shiky/COMP30022-IT-Project"
echo "   docker-compose -f deploy/docker-compose.local.yml up -d"
echo ""

echo "3. 检查服务状态："
echo "   docker-compose -f deploy/docker-compose.local.yml ps"
echo ""

echo "4. 查看日志（如果有问题）："
echo "   docker-compose -f deploy/docker-compose.local.yml logs"
echo ""

echo "📍 访问地址（方案一）："
echo "   🌐 前端应用: http://localhost:3000"
echo "   📡 后端API:  http://localhost:17000" 
echo "   🗄️ 数据库:   mongodb://localhost:27017"
echo ""

echo "💡 生产环境部署时："
echo "   - 将localhost替换为你的Elastic IP地址"
echo "   - 配置防火墙规则（安全组）"
echo "   - 设置SSL证书（可选）"
echo ""

echo "🔄 管理命令："
echo "   停止: docker-compose -f deploy/docker-compose.local.yml down"
echo "   重启: docker-compose -f deploy/docker-compose.local.yml restart"
echo "   更新: docker-compose -f deploy/docker-compose.local.yml up -d --build"
