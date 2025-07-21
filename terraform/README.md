# Terraform AWS部署指南

本项目提供了一个完整的Terraform配置，用于将React + Node.js + MongoDB应用部署到AWS，并支持使用LocalStack进行本地测试。

## 架构概览

### 生产架构（AWS）
- **EC2-1 (Web服务器)**: Nginx + React前端 + Node.js后端
- **EC2-2 (数据库服务器)**: MongoDB + EBS数据盘
- **网络**: VPC + 公有子网 + 私有子网 + NAT网关
- **安全**: 安全组控制访问权限

### 本地测试架构（LocalStack）
- 使用Docker运行LocalStack模拟AWS服务
- 相同的Terraform配置，不同的provider端点

## 前置要求

### 通用要求
- [Terraform](https://terraform.io/downloads.html) >= 1.0
- [Docker](https://docs.docker.com/get-docker/) 和 Docker Compose
- [AWS CLI](https://aws.amazon.com/cli/) (用于AWS部署)
- `curl` 和 `jq` (用于健康检查)

### AWS部署要求
- 配置好的AWS账户和凭证
- 适当的IAM权限 (EC2, EBS, VPC等)

## 快速开始

### 1. LocalStack本地测试

#### 启动LocalStack
```bash
cd terraform

# 方法1: 使用管理脚本
./localstack.sh start

# 方法2: 使用docker-compose
docker-compose -f docker-compose.localstack.yml up -d
```

#### 部署到LocalStack
```bash
# 一键部署到LocalStack
./deploy-localstack.sh
```

#### 管理LocalStack
```bash
# 查看状态
./localstack.sh status

# 查看日志
./localstack.sh logs

# 停止LocalStack
./localstack.sh stop

# 清理数据
./localstack.sh clean

# 启动带Web UI的LocalStack
./localstack.sh web
```

### 2. AWS生产部署

#### 配置AWS凭证
```bash
aws configure
```

#### 部署到AWS
```bash
# 交互式部署到AWS
./deploy-aws.sh
```

## 文件结构

```
terraform/
├── main.tf                      # 主配置文件
├── variables.tf                 # 变量定义
├── outputs.tf                   # 输出定义
├── terraform.tfvars.example     # 变量示例
├── docker-compose.localstack.yml # LocalStack Docker配置
├── deploy-localstack.sh         # LocalStack部署脚本
├── deploy-aws.sh               # AWS部署脚本
├── localstack.sh               # LocalStack管理脚本
├── ec2/
│   └── ec2-instance.tf         # EC2实例配置
├── security/
│   └── security-groups.tf      # 安全组配置
├── volumes/
│   └── ebs.tf                 # EBS卷配置
└── scripts/
    ├── provision-web.sh        # Web服务器初始化脚本
    └── provision-db.sh         # 数据库服务器初始化脚本
```

## 配置说明

### 环境变量配置

创建 `terraform.tfvars` 文件：

```hcl
# 项目配置
project_name = "ani-app"
environment = "development"  # development, staging, production
aws_region = "us-east-1"

# LocalStack配置 (本地测试)
localstack_enabled = true   # false for AWS
localstack_endpoint = "http://localhost:4566"

# 实例类型
instance_type_app = "t3.small"  # Web服务器
instance_type_db = "t3.micro"   # 数据库服务器

# 存储配置
ebs_volume_size = 20  # GB

# SSH密钥 (必须提供)
public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... your-key-here"
```

### LocalStack特殊配置

LocalStack使用的Docker Compose配置包含：
- **端口映射**: 4566 (主端口), 4510-4559 (服务端口)
- **数据持久化**: `./localstack-data` 目录
- **服务**: EC2, EBS, IAM, STS
- **Web UI**: 可选，端口8080

## 部署流程

### LocalStack本地测试流程

1. **启动LocalStack容器**
   ```bash
   ./localstack.sh start
   ```

2. **验证LocalStack运行状态**
   ```bash
   curl http://localhost:4566/health
   ```

3. **部署基础设施**
   ```bash
   ./deploy-localstack.sh
   ```

4. **获取部署信息**
   ```bash
   terraform output
   ```

### AWS生产部署流程

1. **配置AWS凭证**
   ```bash
   aws configure
   ```

2. **运行部署脚本**
   ```bash
   ./deploy-aws.sh
   ```

3. **确认部署**
   - 脚本会显示计划，需要确认后继续

4. **访问应用**
   - 使用输出的URL访问应用

## 应用部署

Terraform会创建基础设施，但应用代码需要单独部署：

### 手动部署
```bash
# SSH到Web服务器
ssh -i ~/.ssh/ani-app-key ubuntu@<web-server-ip>

# 克隆代码
cd /opt/ani-app
git clone <your-repo-url> .

# 运行部署脚本
./deploy.sh
```

### 自动化部署
考虑集成CI/CD流水线：
- GitHub Actions
- AWS CodePipeline
- Jenkins

## 监控和维护

### 健康检查
```bash
# 应用健康检查
curl http://<web-server-ip>/health

# 数据库检查
ssh -i ~/.ssh/ani-app-key ubuntu@<web-server-ip>
mongo <db-server-ip>:27017
```

### 日志查看
```bash
# Web服务器日志
sudo journalctl -u ani-backend -f
sudo tail -f /var/log/nginx/access.log

# 数据库日志
sudo tail -f /var/log/mongodb/mongod.log
```

### 备份
数据库服务器会自动创建每日备份：
```bash
# 查看备份
ls -la /data/backups/

# 手动备份
/opt/mongodb-backup.sh
```

## 故障排除

### LocalStack问题
1. **容器启动失败**
   ```bash
   docker-compose -f docker-compose.localstack.yml logs
   ```

2. **端口冲突**
   ```bash
   # 检查端口占用
   lsof -i :4566
   ```

3. **权限问题**
   ```bash
   # 确保Docker有足够权限
   sudo usermod -aG docker $USER
   ```

### AWS部署问题
1. **权限不足**
   - 检查IAM权限
   - 确保有EC2、VPC、EBS权限

2. **配额限制**
   - 检查AWS服务配额
   - 选择支持的实例类型

3. **网络问题**
   - 检查VPC配置
   - 验证安全组规则

## 成本优化

### 开发环境
- 使用LocalStack进行本地测试
- 使用较小的实例类型 (t3.micro, t3.small)
- 及时销毁测试资源

### 生产环境
- 使用Reserved Instances
- 启用EBS GP3卷类型
- 监控CloudWatch费用警报

## 安全建议

1. **SSH访问**
   - 限制SSH访问IP范围
   - 使用堡垒机访问私有子网

2. **数据库安全**
   - 启用MongoDB认证
   - 加密EBS卷
   - 定期备份

3. **网络安全**
   - 最小权限原则
   - 定期审查安全组规则

## 下一步

1. **CI/CD集成**: 自动化部署流程
2. **监控系统**: 集成CloudWatch或第三方监控
3. **HTTPS支持**: 配置SSL证书
4. **多环境**: 创建staging、production环境
5. **高可用**: 配置多AZ部署

## 联系和支持

如有问题，请查看：
- [Terraform文档](https://terraform.io/docs)
- [LocalStack文档](https://docs.localstack.cloud)
- [AWS文档](https://docs.aws.amazon.com)
