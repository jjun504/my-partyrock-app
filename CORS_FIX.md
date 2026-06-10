# 🔧 CORS 问题修复说明

## 问题描述

部署后访问网站时出现以下错误：
```
Access to fetch at 'https://xxx.lambda-url.ap-southeast-1.on.aws/' 
from origin 'http://xxx.s3-website-ap-southeast-1.amazonaws.com' 
has been blocked by CORS policy
```

## 已修复的内容

### 1. Lambda 函数代码优化

**两个 Lambda 函数都进行了以下改进：**

- ✅ 添加 `@app.after_request` 装饰器，确保所有响应都有 CORS 头
- ✅ 添加 GET 方法的健康检查端点
- ✅ 改进错误处理，在流式传输中捕获异常
- ✅ 简化 OPTIONS 预检请求处理

### 2. SAM 模板配置优化

**infra/template.yaml 更新：**

- ✅ 在 `FunctionUrlConfig` 中添加了 `Cors` 配置块
- ✅ 允许所有来源 (`AllowOrigins: ['*']`)
- ✅ 允许 GET、POST、OPTIONS 方法
- ✅ 允许所有请求头 (`AllowHeaders: ['*']`)
- ✅ 设置预检缓存时间为 300 秒
- ✅ 增加超时时间从 60s 到 120s
- ✅ 增加内存从 256MB 到 512MB
- ✅ 添加 `RUST_LOG: 'info'` 环境变量用于调试

## 重新部署步骤

### 方法 1：通过 Git 推送（推荐）

```bash
cd ai-music-learning-companion

# 提交更改
git add .
git commit -m "Fix CORS issues and improve error handling"
git push origin main
```

GitHub Actions 会自动重新部署（大约 5-7 分钟）。

### 方法 2：本地手动部署

```powershell
cd ai-music-learning-companion

# 设置 AWS 环境变量
$env:AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
$env:AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
$env:AWS_DEFAULT_REGION="ap-southeast-1"

# 构建
sam build --template infra/template.yaml

# 部署
sam deploy `
  --stack-name ai-music-learning-companion `
  --s3-bucket YOUR_SAM_BUCKET_NAME `
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM `
  --region ap-southeast-1 `
  --no-confirm-changeset `
  --no-fail-on-empty-changeset
```

## 测试修复

部署完成后，测试以下内容：

### 1. 测试健康检查

```bash
# 测试 Learning Path 函数
curl https://YOUR_LEARNING_PATH_URL/

# 应该返回：
# {"status":"healthy","service":"personalized_learning_path"}

# 测试 AI Coach 函数
curl https://YOUR_AI_COACH_URL/

# 应该返回：
# {"status":"healthy","service":"ai_music_coach"}
```

### 2. 测试 CORS 预检

```bash
curl -X OPTIONS https://YOUR_LEARNING_PATH_URL/ -H "Origin: http://example.com" -v
```

应该看到响应头中包含：
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: *
```

### 3. 在浏览器中测试

1. 打开你的 S3 网站 URL
2. 填写表单
3. 点击 "Generate My Learning Path"
4. 应该能看到流式响应，没有 CORS 错误

## 如果问题仍然存在

### 检查 CloudWatch 日志

```bash
# 查看 Learning Path 函数日志
aws logs tail /aws/lambda/ai-music-learning-companion-PersonalizedLearningPathFunction --follow

# 查看 AI Coach 函数日志
aws logs tail /aws/lambda/ai-music-learning-companion-AIMusicCoachFunction --follow
```

### 验证 Lambda 函数 URL

```bash
aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query 'Stacks[0].Outputs' \
  --region ap-southeast-1
```

确保前端 `index.html` 中的 URL 与输出中的 URL 匹配。

### 检查 Bedrock 模型访问

```bash
aws bedrock list-foundation-models \
  --region ap-southeast-1 \
  --by-provider anthropic \
  --query 'modelSummaries[?contains(modelId, `claude-sonnet-4-6`)]'
```

确保你有访问 Claude Sonnet 4.6 的权限。

## 主要改进点总结

| 改进项 | 修复前 | 修复后 |
|--------|--------|--------|
| CORS 头 | 仅在路由中设置 | 全局设置（@app.after_request） |
| FunctionUrlConfig | 无 CORS 配置 | 添加完整 CORS 配置 |
| 健康检查 | 无 | 添加 GET / 端点 |
| 错误处理 | 基础 | 改进的流式错误处理 |
| 超时时间 | 60s | 120s |
| 内存 | 256MB | 512MB |
| 日志级别 | 默认 | 添加 RUST_LOG=info |

## 预期结果

修复后，你应该能够：

✅ 无 CORS 错误访问网站
✅ 成功生成学习路径
✅ 与 AI 教练聊天
✅ 看到实时流式响应
✅ 在浏览器控制台中没有错误

---

**修复完成！现在请重新部署并测试。** 🚀
