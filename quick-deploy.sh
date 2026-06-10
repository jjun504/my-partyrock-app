#!/bin/bash

# Quick Deploy Script for AI Music Learning Companion
# This script automates the entire deployment process

set -e  # Exit on error

echo "🎵 AI Music Learning Companion - Quick Deploy Script"
echo "=================================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

if ! command -v sam &> /dev/null; then
    echo "❌ AWS SAM CLI not found. Please install it first."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 not found. Please install it first."
    exit 1
fi

echo "✅ All prerequisites met"
echo ""

# Get SAM deployment bucket
echo "Enter your SAM deployment bucket name:"
read -p "Bucket name: " SAM_BUCKET

if [ -z "$SAM_BUCKET" ]; then
    echo "❌ Bucket name cannot be empty"
    exit 1
fi

# Confirm deployment
echo ""
echo "📋 Deployment Configuration:"
echo "   Stack Name: ai-music-learning-companion"
echo "   Region: ap-southeast-1"
echo "   SAM Bucket: $SAM_BUCKET"
echo ""
read -p "Continue with deployment? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ]; then
    echo "Deployment cancelled"
    exit 0
fi

echo ""
echo "🔨 Building SAM application..."
sam build --template infra/template.yaml

echo ""
echo "🚀 Deploying to AWS..."
sam deploy \
  --stack-name ai-music-learning-companion \
  --s3-bucket $SAM_BUCKET \
  --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM \
  --region ap-southeast-1 \
  --no-confirm-changeset \
  --no-fail-on-empty-changeset

echo ""
echo "📤 Getting deployment outputs..."

# Helper function to get CloudFormation output
get_output() {
    aws cloudformation describe-stacks \
        --stack-name ai-music-learning-companion \
        --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" \
        --output text \
        --region ap-southeast-1
}

LEARNING_PATH_URL=$(get_output PersonalizedLearningPathUrl)
COACH_URL=$(get_output AIMusicCoachUrl)
BUCKET_NAME=$(get_output BucketName)
WEBSITE_URL=$(get_output WebsiteUrl)

echo "✅ Deployment outputs retrieved"
echo ""

echo "🔧 Injecting Lambda URLs into frontend..."
cp frontend/index.html frontend/index.html.backup
sed -i.bak "s|__URL_PERSONALIZED_LEARNING_PATH__|$LEARNING_PATH_URL|g" frontend/index.html
sed -i.bak "s|__URL_AI_MUSIC_COACH__|$COACH_URL|g" frontend/index.html
rm -f frontend/index.html.bak

echo ""
echo "📤 Uploading frontend to S3..."
aws s3 sync frontend/ s3://$BUCKET_NAME/ --cache-control no-cache --delete --region ap-southeast-1

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "=================================================="
echo "📋 Deployment Summary:"
echo "=================================================="
echo ""
echo "🌐 Website URL:"
echo "   $WEBSITE_URL"
echo ""
echo "🔗 API Endpoints:"
echo "   Learning Path: $LEARNING_PATH_URL"
echo "   AI Coach: $COACH_URL"
echo ""
echo "📦 S3 Bucket: $BUCKET_NAME"
echo ""
echo "=================================================="
echo ""
echo "🎵 Open the website URL in your browser to start using the app!"
echo ""

# Restore original frontend file
mv frontend/index.html.backup frontend/index.html 2>/dev/null || true
