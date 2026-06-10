# 🎵 AI Music Learning Companion

Your personalized path to musical mastery, powered by AWS and AI.

---

## 🚀 **New to this project? → [START HERE!](START_HERE.md)**

---

## Overview

The AI Music Learning Companion creates a personalized music education experience tailored to your chosen instrument, skill level, and preferred musical genres. It generates a customized learning path and provides an interactive AI coach to guide your musical journey.

## Features

- **Personalized Learning Paths**: Custom curriculum based on your instrument, skill level, and genre preferences
- **AI Music Coach**: Interactive chat interface for real-time guidance and feedback
- **Streaming Responses**: Real-time token-by-token AI responses for a natural conversation flow
- **Responsive Design**: Works seamlessly on mobile and desktop devices

## Architecture

- **Frontend**: Single-page HTML/CSS/JS application hosted on AWS S3
- **Backend**: Python Flask Lambda functions with streaming responses
- **AI**: Amazon Bedrock with Claude Sonnet 4.6 model
- **Infrastructure**: AWS SAM (Serverless Application Model)
- **CI/CD**: GitHub Actions for automated deployment

## Pre-Deployment Checklist

Before deploying this application, you must:

### 1. Enable Amazon Bedrock Model Access

1. Go to AWS Console → Amazon Bedrock → Model Access
2. Request access to: **Claude Sonnet 4.6 (global.anthropic.claude-sonnet-4-6-20260217-v1:0)**
3. Region: **ap-southeast-1** (Singapore)
4. First-time accounts may need to submit a use-case form
5. Wait for approval (usually instant for most accounts)

### 2. Create S3 Bucket for SAM Deployments

```bash
aws s3 mb s3://your-sam-deploy-bucket --region ap-southeast-1
```

### 3. Set Up GitHub Secrets

In your GitHub repository, go to Settings → Secrets and variables → Actions, and add:

- `AWS_ACCESS_KEY_ID`: Your AWS access key ID
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key
- `SAM_DEPLOY_BUCKET`: Name of the S3 bucket created in step 2 (e.g., `your-sam-deploy-bucket`)

## Local Development

### Prerequisites

- Python 3.12+
- AWS SAM CLI
- AWS CLI configured with credentials

### Build and Deploy

```bash
# Build the SAM application
sam build --template infra/template.yaml

# Deploy to AWS
sam deploy \
  --stack-name ai-music-learning-companion \
  --s3-bucket your-sam-deploy-bucket \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region ap-southeast-1 \
  --no-confirm-changeset
```

### Get Deployment URLs

```bash
aws cloudformation describe-stacks \
  --stack-name ai-music-learning-companion \
  --query 'Stacks[0].Outputs' \
  --output table
```

## Deployment via GitHub Actions

1. Push your code to the `main` branch
2. GitHub Actions will automatically:
   - Build the SAM application
   - Deploy Lambda functions and infrastructure
   - Upload the frontend to S3
   - Output the website URL

## Usage

1. **Select Your Instrument**: Choose from guitar, piano, violin, saxophone, drums, bass, voice, or other
2. **Choose Your Skill Level**: Beginner, Intermediate, Advanced, or Professional
3. **Enter Genre Preferences**: Type your favorite musical genres (e.g., Jazz, Rock, Classical)
4. **Generate Learning Path**: Click the button to create your personalized curriculum
5. **Chat with AI Coach**: Ask questions and get guidance tailored to your learning path

## Tech Stack

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Backend**: Python 3.12, Flask
- **AI Model**: Anthropic Claude Sonnet 4.6 (via Amazon Bedrock)
- **Infrastructure**: AWS Lambda, S3, IAM
- **IaC**: AWS SAM
- **CI/CD**: GitHub Actions

## Model Information

This application uses the **Claude Sonnet 4.6** model via Amazon Bedrock with the global cross-region inference profile:

- Model ID: `global.anthropic.claude-sonnet-4-6-20260217-v1:0`
- The `global.` prefix enables worldwide routing for maximum throughput
- Automatically routes to the best available region (us-east-2, us-west-2, etc.)

## Cost Considerations

- **Amazon Bedrock**: Pay-per-token pricing for Claude Sonnet 4.6
- **AWS Lambda**: Pay-per-invocation and compute time (very low for typical usage)
- **S3**: Minimal storage and bandwidth costs
- **Estimated monthly cost**: $5-20 for moderate usage (depends on conversation length)

## License

MIT License - Feel free to use and modify for your own projects.

## Support

For issues or questions, please open a GitHub issue or contact the maintainer.

---

Built with ❤️ using AWS and Anthropic Claude
