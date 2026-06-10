# ⚡ Quick Start Guide

Get your AI Music Learning Companion up and running in 10 minutes!

## 🚀 Fastest Path to Deployment

### 1️⃣ Enable Bedrock Access (2 minutes)

```bash
# Open AWS Console
# Go to: Bedrock → Model Access → Enable Claude Sonnet 4.6
# Region: ap-southeast-1 (Singapore)
```

### 2️⃣ Create SAM Bucket (1 minute)

```bash
aws s3 mb s3://ai-music-sam-$(date +%s) --region ap-southeast-1
# Save the bucket name!
```

### 3️⃣ Configure GitHub Secrets (2 minutes)

Go to: **GitHub Repo → Settings → Secrets → Actions**

Add these secrets:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `SAM_DEPLOY_BUCKET` (from step 2)

### 4️⃣ Deploy via GitHub Actions (5 minutes)

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/ai-music-learning-companion.git
git push -u origin main
```

Watch the deployment in the **Actions** tab!

---

## 🖥️ Local Deployment (Alternative)

### Prerequisites

```bash
# Check installations
aws --version          # AWS CLI
sam --version          # AWS SAM CLI
python --version       # Python 3.12+
```

### Deploy

**On Windows:**
```powershell
.\quick-deploy.ps1
```

**On Linux/macOS:**
```bash
chmod +x quick-deploy.sh
./quick-deploy.sh
```

### Manual Steps

```bash
# 1. Build
sam build --template infra/template.yaml

# 2. Deploy
sam deploy \
  --stack-name ai-music-learning-companion \
  --s3-bucket YOUR_SAM_BUCKET \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region ap-southeast-1 \
  --no-confirm-changeset

# 3. Get outputs
aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query 'Stacks[0].Outputs' \
  --region ap-southeast-1 \
  --output table

# 4. Update frontend (see DEPLOYMENT_GUIDE.md for full commands)
```

---

## ✅ Verify Deployment

### Test the Website

1. Open the website URL from deployment outputs
2. Fill in:
   - **Instrument**: Guitar
   - **Skill Level**: Intermediate
   - **Genre**: Jazz, Blues
3. Click **Generate My Learning Path**
4. Wait for streaming response (10-30 seconds)
5. Ask the coach: *"What should I practice first?"*

### Check Logs

```bash
# View Lambda logs
sam logs --stack-name ai-music-learning-companion \
  --name PersonalizedLearningPathFunction \
  --region ap-southeast-1 \
  --tail
```

---

## 🐛 Common Issues

### "AccessDeniedException: Could not access bedrock"
→ Enable Bedrock model access in AWS Console

### "Bucket does not exist"
→ Verify SAM bucket name is correct

### Frontend shows connection errors
→ Check Lambda Function URLs are injected correctly

### No streaming response
→ Verify CORS headers in Lambda responses

---

## 📚 Next Steps

- **Read**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) for detailed instructions
- **Explore**: [PROJECT_STRUCTURE.md](PROJECT_STRUCTURE.md) to understand the code
- **Customize**: Modify prompts in `backend/*/app.py`
- **Extend**: Add new instruments or features

---

## 💰 Cost Estimate

**Moderate usage** (100 conversations/month):
- Bedrock: $10-15
- Lambda: $0.50
- S3: $0.10
- **Total**: ~$10-20/month

---

## 🆘 Need Help?

1. Check [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) troubleshooting section
2. View CloudWatch Logs for errors
3. Verify Bedrock model access is enabled
4. Ensure all GitHub secrets are set correctly

---

## 🎵 Enjoy Your Musical Journey!

Your AI Music Learning Companion is ready to help you master your instrument. Happy practicing! 🎸🎹🎻🎷🥁
