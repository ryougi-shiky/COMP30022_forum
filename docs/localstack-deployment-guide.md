# LocalStack AWS 模拟环境部署指南

本文档说明如何使用 LocalStack 模拟 AWS 环境，通过 Terraform 部署基础设施，并运行 E2E 测试。

## 推荐的 AWS 技术栈

### 架构概览
```
Internet → ALB → ECS Fargate (Frontend + Backend) → MongoDB (ECS)
                     ↓
               Service Discovery (Private DNS)
```

### 技术栈组件

**前端 (React + Nginx):**
- AWS Application Load Balancer (ALB) - 负载均衡和路由
- ECS Fargate - 容器化部署，无服务器管理
- CloudWatch Logs - 日志收集

**后端 (Node.js Express):**
- ECS Fargate - 自动扩缩容的容器服务
- Service Discovery - 服务间通信
- CloudWatch Logs - 应用日志

**数据库:**
- MongoDB on ECS Fargate - 容器化 MongoDB
- Service Discovery - 私有 DNS 解析

**网络:**
- VPC - 隔离的虚拟网络
- 公有子网 - ALB 和 NAT Gateway
- 私有子网 - ECS 任务和数据库
- NAT Gateway - 私有子网访问互联网

## 快速开始

### 1. 环境要求
```bash
# 安装依赖
brew install terraform awscli docker
```

### 2. 启动 LocalStack 环境并部署
```bash
# 一键启动和部署
./auto/setup-localstack
```

### 3. 运行 E2E 测试
```bash
# 针对 LocalStack 环境运行 E2E 测试
./auto/run-e2e-tests-localstack
```

### 4. 清理环境
```bash
# 清理所有资源
./auto/cleanup-localstack
```

## 详细步骤

### 步骤 1: LocalStack 环境启动
LocalStack 模拟以下 AWS 服务：
- ECS (Elastic Container Service)
- EC2 (VPC, 子网, 安全组)
- ELB v2 (Application Load Balancer)
- CloudWatch Logs
- Service Discovery
- IAM (角色和策略)

### 步骤 2: 基础设施部署
Terraform 创建的资源：
- VPC 和网络组件 (公有/私有子网, NAT Gateway)
- ECS 集群和服务
- Application Load Balancer
- 安全组和 IAM 角色
- CloudWatch 日志组
- Service Discovery 命名空间

### 步骤 3: 应用程序部署
- 构建 Docker 镜像
- 推送到 LocalStack ECR
- 部署 ECS 服务
- 配置负载均衡器路由

## 架构优势

### 1. 生产环境一致性
- 使用相同的 AWS 服务架构
- Terraform 代码可直接用于真实 AWS 部署
- 容器化确保环境一致性

### 2. 可扩展性
- ECS Fargate 自动扩缩容
- ALB 提供高可用性负载均衡
- 微服务架构便于独立扩展

### 3. 安全性
- VPC 网络隔离
- 私有子网部署应用
- 安全组控制网络访问

### 4. 可观测性
- CloudWatch 集中日志收集
- 健康检查监控
- 服务发现简化服务间通信

## 文件结构
```
deploy/
├── docker-compose.localstack.yml  # LocalStack 环境配置
terraform/
├── providers.tf                   # Terraform 提供者配置
├── vpc.tf                        # VPC 和网络配置
├── security_groups.tf            # 安全组配置
├── ecs.tf                        # ECS 集群和 ALB
├── task_definitions.tf           # ECS 任务定义
├── services.tf                   # ECS 服务配置
├── service_discovery.tf          # 服务发现配置
├── variables.tf                  # 变量定义
└── outputs.tf                    # 输出配置
auto/
├── setup-localstack             # 环境设置脚本
├── run-e2e-tests-localstack     # E2E 测试脚本
└── cleanup-localstack           # 清理脚本
```

## 测试流程

1. **环境准备**: LocalStack 启动，模拟 AWS 服务
2. **基础设施部署**: Terraform 创建所有 AWS 资源
3. **应用部署**: Docker 镜像构建和 ECS 服务启动
4. **健康检查**: 等待所有服务就绪
5. **E2E 测试**: Cypress 测试执行
6. **环境清理**: 清理所有资源

## 故障排除

### 常见问题
1. **LocalStack 服务未就绪**: 等待更长时间或检查 Docker 资源
2. **ECS 任务启动失败**: 检查 CloudWatch 日志
3. **网络连接问题**: 验证安全组和路由表配置
4. **DNS 解析失败**: 确认 Service Discovery 配置正确

### 调试命令
```bash
# 查看 LocalStack 服务状态
curl http://localhost:4566/_localstack/health

# 查看 Terraform 状态
cd terraform && terraform show

# 查看 ECS 服务状态
aws --endpoint-url=http://localhost:4566 ecs describe-services \
    --cluster ani-cluster --services ani-backend ani-frontend

# 查看容器日志
docker logs <container_id>
```

这套解决方案为你提供了一个完整的 AWS 环境模拟，可以在本地进行开发和测试，确保与生产环境的一致性。
