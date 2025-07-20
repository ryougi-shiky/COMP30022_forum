# EC2 based AWS架构方案

## 🏗️ 推荐架构

### 简化的EC2架构
```
Internet → ALB/NLB → EC2实例 (前端+后端) → EBS卷 (数据库)
             ↓
       安全组控制访问
```

### 更经济的单实例架构
```
Internet → Elastic IP → EC2实例 (Nginx + Node.js + MongoDB) → EBS卷
```

## 💰 网络暴露方案成本分析

### 方案1: Application Load Balancer (ALB) - 推荐
- **成本**: ~$16/月 (固定) + 数据传输费
- **优势**: 
  - 支持HTTPS/SSL终止
  - 基于路径的路由 (前端和API分离)
  - 健康检查和高可用
  - 自动扩展支持
- **免费额度**: 新用户12个月内有限制性免费使用

### 方案2: Network Load Balancer (NLB)
- **成本**: ~$16/月 + 数据传输费
- **优势**: 超高性能，支持TCP/UDP
- **劣势**: 不支持HTTP层功能

### 方案3: API Gateway (不推荐用于全站)
- **成本**: 按请求计费 ($3.50/百万请求)
- **限制**: 主要用于API，不适合前端静态文件
- **免费额度**: 每月100万请求

### 方案4: 直接使用Elastic IP (最经济)
- **成本**: $0 (只要EC2在运行)
- **限制**: 单实例，无负载均衡，需手动SSL配置
- **适用**: 开发/测试环境或小型应用

### 方案5: CloudFront + ALB (生产推荐)
- **成本**: CloudFront按流量计费 + ALB费用
- **优势**: 全球CDN加速，SSL自动管理
- **免费额度**: 每月1TB数据传输

## 🎯 推荐方案配置

### 开发/测试环境 (最经济)
```yaml
单个t3.small EC2实例 + Elastic IP
- 前端: Nginx静态文件服务
- 后端: Node.js Express
- 数据库: MongoDB (数据存储在EBS)
- 成本: ~$15/月
```

### 生产环境 (推荐)
```yaml
ALB + 1-2个EC2实例
- 前端: S3 + CloudFront
- 后端: EC2上的Node.js + ALB
- 数据库: EC2上的MongoDB + EBS
- 成本: ~$40-60/月
```

## 🛠️ LocalStack免费服务支持

LocalStack Community版本支持以下服务测试:
- ✅ EC2 (基础实例管理)
- ✅ S3 (文件存储)
- ✅ API Gateway (基础功能)
- ✅ Lambda (简单函数)
- ✅ VPC, 安全组, 路由表
- ❌ ALB/NLB (Pro功能)
- ❌ ECS (Pro功能)

因此我建议采用 **EC2 + Elastic IP** 的架构，这样可以：
1. 在LocalStack中完全测试
2. 生产环境成本可控
3. 架构简单易维护
