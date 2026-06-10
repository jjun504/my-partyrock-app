# 📋 Deployment Guide - AI Music Learning Companion

Follow these steps to deploy your AI Music Learning Companion to AWS.

## Prerequisites Checklist

- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI installed and configured
- [ ] Python 3.12+ installed
- [ ] AWS SAM CLI installed
- [ ] GitHub repository created

## Step 1: Enable Amazon Bedrock Model Access

### Via AWS Console

1. Log into AWS Console
2. Navigate to **Amazon Bedrock** service
3. Select region: **ap-southeast-1** (Singapore)
4. Click on **Model access** in the left sidebar
5. Click **Enable specific models** or **Manage model access**
6. Find and enable:
   - **Claude Sonnet 4.6** (`global.anthropic.claude-sonnet-4-6-20260217-v1:0`)
7. Submit the request
8. Wait for approval (usually instant)

### Via AWS CLI

```bash
aws bedrock list-foundation-models --region ap-southeast-1 \
  --by-provider anthropic \
  --query 'modelSummaries[?contains(modelId, `claude-sonnet-4-6`)].modelId'
```

**Note**: First-time Bedrock users may need to fill out a use-case form. Approval is typically granted within minutes.

## Step 2: Create SAM Deployment Bucket

Create an S3 bucket for SAM to store deployment artifacts:

```bash
# Replace 'your-unique-bucket-name' with your own unique bucket name
aws s3 mb s3://ai-music-companion-sam-deploy-$(date +%s) --region ap-southeast-1
```

Save the bucket name for later use.

## Step 3: Set Up AWS Credentials

### For Local Development

Ensure AWS CLI is configured:

```bash
aws configure
```

Enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `ap-southeast-1`
- Default output format: `json`

### For GitHub Actions

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

| Secret Name | Value |
|-------------|-------|
| `AWS_ACCESS_KEY_ID` | Your AWS Access Key ID |
| `AWS_SECRET_ACCESS_KEY` | Your AWS Secret Access Key |
| `SAM_DEPLOY_BUCKET` | The S3 bucket name from Step 2 |

## Step 4: Deploy the Application

### Option A: Deploy via GitHub Actions (Recommended)

1. Push your code to GitHub:

```bash
git init
git add .
git commit -m "Initial commit: AI Music Learning Companion"
git remote add origin https://github.com/your-username/ai-music-learning-companion.git
git push -u origin main
```

2. GitHub Actions will automatically deploy the application
3. Monitor the deployment in the **Actions** tab
4. Once complete, check the workflow output for the website URL

### Option B: Deploy Locally via SAM CLI

1. Navigate to the project directory:

```bash
cd ai-music-learning-companion
```

2. Build the SAM application:

```bash
sam build --template infra/template.yaml
```

3. Deploy to AWS:

```bash
sam deploy \
  --stack-name ai-music-learning-companion \
  --s3-bucket your-sam-deploy-bucket \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region ap-southeast-1 \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset
```

4. Get the deployment outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query 'Stacks[0].Outputs' \
  --region ap-southeast-1 \
  --output table
```

5. Update the frontend with Lambda URLs:

```bash
# Get the Lambda Function URLs
LEARNING_PATH_URL=$(aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query "Stacks[0].Outputs[?OutputKey=='PersonalizedLearningPathUrl'].OutputValue" \
  --output text \
  --region ap-southeast-1)

COACH_URL=$(aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query "Stacks[0].Outputs[?OutputKey=='AIMusicCoachUrl'].OutputValue" \
  --output text \
  --region ap-southeast-1)

BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" \
  --output text \
  --region ap-southeast-1)

# Inject URLs into frontend
sed -i "s|__URL_PERSONALIZED_LEARNING_PATH__|$LEARNING_PATH_URL|g" frontend/index.html
sed -i "s|__URL_AI_MUSIC_COACH__|$COACH_URL|g" frontend/index.html

# Upload to S3
aws s3 sync frontend/ s3://$BUCKET_NAME/ --cache-control no-cache --delete --region ap-southeast-1
```

6. Get your website URL:

```bash
aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query "Stacks[0].Outputs[?OutputKey=='WebsiteUrl'].OutputValue" \
  --output text \
  --region ap-southeast-1
```

## Step 5: Test the Application

1. Open the website URL in your browser
2. Select an instrument (e.g., Guitar)
3. Choose your skill level (e.g., Intermediate)
4. Enter genre preferences (e.g., Jazz, Blues)
5. Click **Generate My Learning Path**
6. Wait for the AI to generate your personalized curriculum
7. Test the chat feature by asking questions like:
   - "What chord progressions should I practice first?"
   - "How can I improve my improvisation skills?"
   - "What practice routine do you recommend?"

## Troubleshooting

### Error: "AccessDeniedException" when calling Bedrock

**Solution**: Ensure you've enabled model access in the Bedrock console for the Claude Sonnet 4.6 model in the ap-southeast-1 region.

### Error: "Bucket does not exist" during SAM deploy

**Solution**: Verify the S3 bucket name in your GitHub secrets or local command matches the bucket you created.

### Error: Lambda function timeout

**Solution**: The default timeout is 60 seconds. For longer conversations, you may need to increase this in the SAM template.

### Frontend shows "Error: Failed to fetch"

**Solution**: 
1. Check that Lambda Function URLs are correctly injected into the frontend
2. Verify CORS headers are properly set in the Lambda responses
3. Check CloudWatch Logs for Lambda errors

### Commands to view logs

```bash
# View logs for Learning Path function
sam logs --stack-name ai-music-learning-companion \
  --name PersonalizedLearningPathFunction \
  --region ap-southeast-1 \
  --tail

# View logs for AI Coach function
sam logs --stack-name ai-music-learning-companion \
  --name AIMusicCoachFunction \
  --region ap-southeast-1 \
  --tail
```

## Clean Up Resources

To delete all AWS resources created by this application:

```bash
# Delete S3 bucket contents first
BUCKET_NAME=$(aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" \
  --output text \
  --region ap-southeast-1)

aws s3 rm s3://$BUCKET_NAME --recursive --region ap-southeast-1

# Delete the CloudFormation stack
aws cloudformation delete-stack \
  --stack-name ai-music-learning-companion \
  --region ap-southeast-1

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete \
  --stack-name ai-music-learning-companion \
  --region ap-southeast-1
```

## Cost Estimation

Approximate monthly costs for moderate usage (100 conversations/month):

- **Amazon Bedrock**: ~$10-15 (based on token usage)
- **AWS Lambda**: ~$0.50 (invocations + compute time)
- **S3**: ~$0.10 (storage + bandwidth)
- **Total**: ~$10-20/month

For high-volume production use, costs will scale with usage.

## Next Steps

- Set up a custom domain using Route 53 and CloudFront
- Add authentication using Amazon Cognito
- Implement conversation history persistence with DynamoDB
- Add monitoring and alerting with CloudWatch
- Set up WAF rules for additional security

## Support

For issues or questions:
- Check CloudWatch Logs for detailed error messages
- Review the AWS SAM documentation
- Open a GitHub issue in your repository

---

🎵 Happy music learning!
