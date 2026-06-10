# ✅ Pre-Deployment Checklist

Complete this checklist before deploying your AI Music Learning Companion.

## 📋 AWS Account Setup

### 1. AWS Account Access

- [ ] I have an active AWS account
- [ ] I have AWS CLI installed on my machine
- [ ] I have configured AWS credentials locally (`aws configure`)
- [ ] My IAM user has appropriate permissions:
  - [ ] CloudFormation (create/update/delete stacks)
  - [ ] Lambda (create/update functions)
  - [ ] S3 (create/manage buckets)
  - [ ] IAM (create roles and policies)
  - [ ] Bedrock (invoke models)

**Test your credentials:**
```bash
aws sts get-caller-identity
```

---

## 🤖 Amazon Bedrock Setup

### 2. Enable Bedrock Model Access

- [ ] I have logged into AWS Console
- [ ] I have navigated to Amazon Bedrock service
- [ ] I have selected region: **ap-southeast-1** (Singapore)
- [ ] I have clicked "Model access" in the left sidebar
- [ ] I have requested access to: **Claude Sonnet 4.6**
  - Model ID: `global.anthropic.claude-sonnet-4-6-20260217-v1:0`
- [ ] My request has been approved (status shows "Access granted")

**Note:** First-time users may need to complete a use-case form. Approval typically takes a few minutes.

**Verify access:**
```bash
aws bedrock list-foundation-models --region ap-southeast-1 --by-provider anthropic
```

---

## 🪣 S3 Deployment Bucket

### 3. Create SAM Deployment Bucket

- [ ] I have created an S3 bucket for SAM deployments
- [ ] The bucket name is unique and saved somewhere safe
- [ ] The bucket is in region **ap-southeast-1**

**Create bucket:**
```bash
# Replace with your own unique name
aws s3 mb s3://my-sam-deploy-bucket-$(date +%s) --region ap-southeast-1
```

**Save the bucket name** - you'll need it for deployment!

---

## 🔧 Local Development Tools (Optional - for local deployment)

### 4. Install Required Tools

If deploying locally (not via GitHub Actions), install:

- [ ] **Python 3.12+**
  ```bash
  python --version
  ```

- [ ] **AWS SAM CLI**
  ```bash
  sam --version
  ```

- [ ] **Git**
  ```bash
  git --version
  ```

**Installation guides:**
- Python: https://www.python.org/downloads/
- SAM CLI: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
- Git: https://git-scm.com/downloads

---

## 🐙 GitHub Setup (For GitHub Actions Deployment)

### 5. GitHub Repository

- [ ] I have created a GitHub repository for this project
- [ ] I have cloned/initialized the repository locally
- [ ] I have committed all project files

**Setup repository:**
```bash
cd ai-music-learning-companion
git init
git add .
git commit -m "Initial commit: AI Music Learning Companion"
git remote add origin https://github.com/YOUR_USERNAME/ai-music-learning-companion.git
git push -u origin main
```

---

### 6. GitHub Secrets

- [ ] I have navigated to: **GitHub Repo → Settings → Secrets and variables → Actions**
- [ ] I have added the following secrets:

| Secret Name | Value | Status |
|-------------|-------|--------|
| `AWS_ACCESS_KEY_ID` | Your AWS access key ID | [ ] Added |
| `AWS_SECRET_ACCESS_KEY` | Your AWS secret access key | [ ] Added |
| `SAM_DEPLOY_BUCKET` | S3 bucket name from step 3 | [ ] Added |

**Security note:** Never commit AWS credentials to Git!

---

## 🔍 Pre-Flight Verification

### 7. Final Checks

- [ ] All files are present (run `dir` or `ls -R` in project root)
- [ ] AWS credentials are valid and have correct permissions
- [ ] Bedrock model access is approved
- [ ] SAM deployment bucket exists and is accessible
- [ ] GitHub secrets are configured (if using GitHub Actions)
- [ ] I have read the DEPLOYMENT_GUIDE.md

---

## 🚀 Ready to Deploy!

### Choose Your Deployment Method:

#### Option A: GitHub Actions (Recommended)
```bash
git push origin main
```
Then monitor deployment in the **Actions** tab.

#### Option B: Windows PowerShell Script
```powershell
.\quick-deploy.ps1
```

#### Option C: Bash Script (Linux/macOS)
```bash
chmod +x quick-deploy.sh
./quick-deploy.sh
```

#### Option D: Manual SAM Commands
See **DEPLOYMENT_GUIDE.md** for step-by-step commands.

---

## 📊 Post-Deployment Verification

### 8. Test Your Deployment

- [ ] GitHub Actions workflow completed successfully (if using Actions)
- [ ] CloudFormation stack status is "CREATE_COMPLETE"
- [ ] I can access the website URL
- [ ] Website loads without errors
- [ ] Form submission generates learning path
- [ ] AI coach responds to questions
- [ ] No errors in browser console

**Run automated tests:**
```powershell
.\test-deployment.ps1
```

---

## 🐛 Troubleshooting

### If something goes wrong:

1. **Check CloudFormation stack status:**
   ```bash
   aws cloudformation describe-stacks --stack-name ai-music-learning-companion --region ap-southeast-1
   ```

2. **View Lambda logs:**
   ```bash
   sam logs --stack-name ai-music-learning-companion --name PersonalizedLearningPathFunction --region ap-southeast-1 --tail
   ```

3. **Verify Bedrock access:**
   ```bash
   aws bedrock list-foundation-models --region ap-southeast-1
   ```

4. **Check S3 bucket:**
   ```bash
   aws s3 ls s3://YOUR_BUCKET_NAME --region ap-southeast-1
   ```

5. **Review DEPLOYMENT_GUIDE.md** for detailed troubleshooting steps

---

## 📝 Common Issues

### ❌ "AccessDeniedException" when calling Bedrock
**Solution:** Enable Bedrock model access in AWS Console for Claude Sonnet 4.6 in ap-southeast-1 region.

### ❌ "NoSuchBucket" error during SAM deploy
**Solution:** Verify the SAM deployment bucket name is correct and exists in ap-southeast-1.

### ❌ GitHub Actions fails with "Unable to locate credentials"
**Solution:** Check that AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY secrets are set correctly in GitHub.

### ❌ Lambda function timeout
**Solution:** Bedrock responses can take 10-30 seconds. The default 60s timeout should be sufficient for most cases.

### ❌ CORS errors in browser
**Solution:** Verify Lambda functions are returning proper CORS headers. Check Lambda code and redeploy if needed.

---

## 📚 Additional Resources

- **Quick Start:** QUICK_START.md
- **Detailed Deployment:** DEPLOYMENT_GUIDE.md
- **Project Structure:** PROJECT_STRUCTURE.md
- **Overview:** OVERVIEW.md

---

## ✅ Checklist Complete!

If you've checked all the boxes above, you're ready to deploy! 🚀

**Estimated deployment time:**
- Via GitHub Actions: 5-7 minutes
- Via quick deploy script: 8-10 minutes
- Manual deployment: 15-20 minutes

Good luck! 🎵

---

## 💰 Cost Reminder

**Approximate monthly cost for moderate usage (100 conversations):**
- Amazon Bedrock: $10-15
- AWS Lambda: $0.50
- S3: $0.10
- **Total: ~$10-20/month**

Set up AWS Budgets alerts to monitor costs!

---

## 🆘 Need Help?

1. Review the troubleshooting section above
2. Check DEPLOYMENT_GUIDE.md for detailed instructions
3. View CloudWatch Logs for error details
4. Verify all prerequisites are met
5. Run test-deployment.ps1 to diagnose issues

---

**Last updated:** 2026-06-09
**Project:** AI Music Learning Companion
**Version:** 1.0
