# Quick Deploy Script for AI Music Learning Companion (PowerShell)
# This script automates the entire deployment process on Windows

$ErrorActionPreference = "Stop"

Write-Host "🎵 AI Music Learning Companion - Quick Deploy Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

$awsInstalled = Get-Command aws -ErrorAction SilentlyContinue
if (-not $awsInstalled) {
    Write-Host "❌ AWS CLI not found. Please install it first." -ForegroundColor Red
    exit 1
}

$samInstalled = Get-Command sam -ErrorAction SilentlyContinue
if (-not $samInstalled) {
    Write-Host "❌ AWS SAM CLI not found. Please install it first." -ForegroundColor Red
    exit 1
}

$pythonInstalled = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonInstalled) {
    Write-Host "❌ Python not found. Please install it first." -ForegroundColor Red
    exit 1
}

Write-Host "✅ All prerequisites met" -ForegroundColor Green
Write-Host ""

# Get SAM deployment bucket
$SAM_BUCKET = Read-Host "Enter your SAM deployment bucket name"

if ([string]::IsNullOrWhiteSpace($SAM_BUCKET)) {
    Write-Host "❌ Bucket name cannot be empty" -ForegroundColor Red
    exit 1
}

# Confirm deployment
Write-Host ""
Write-Host "📋 Deployment Configuration:" -ForegroundColor Cyan
Write-Host "   Stack Name: ai-music-learning-companion"
Write-Host "   Region: ap-southeast-1"
Write-Host "   SAM Bucket: $SAM_BUCKET"
Write-Host ""
$CONFIRM = Read-Host "Continue with deployment? (y/n)"

if ($CONFIRM -ne "y") {
    Write-Host "Deployment cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "🔨 Building SAM application..." -ForegroundColor Yellow
sam build --template infra/template.yaml

Write-Host ""
Write-Host "🚀 Deploying to AWS..." -ForegroundColor Yellow
sam deploy `
    --stack-name ai-music-learning-companion `
    --s3-bucket $SAM_BUCKET `
    --capabilities CAPABILITY_IAM CAPABILITY_NAMED_IAM `
    --region ap-southeast-1 `
    --no-confirm-changeset `
    --no-fail-on-empty-changeset

Write-Host ""
Write-Host "📤 Getting deployment outputs..." -ForegroundColor Yellow

# Helper function to get CloudFormation output
function Get-StackOutput {
    param($OutputKey)
    
    $output = aws cloudformation describe-stacks `
        --stack-name ai-music-learning-companion `
        --query "Stacks[0].Outputs[?OutputKey=='$OutputKey'].OutputValue" `
        --output text `
        --region ap-southeast-1
    
    return $output
}

$LEARNING_PATH_URL = Get-StackOutput "PersonalizedLearningPathUrl"
$COACH_URL = Get-StackOutput "AIMusicCoachUrl"
$BUCKET_NAME = Get-StackOutput "BucketName"
$WEBSITE_URL = Get-StackOutput "WebsiteUrl"

Write-Host "✅ Deployment outputs retrieved" -ForegroundColor Green
Write-Host ""

Write-Host "🔧 Injecting Lambda URLs into frontend..." -ForegroundColor Yellow

# Create a backup
Copy-Item frontend/index.html frontend/index.html.backup -Force

# Read the file
$content = Get-Content frontend/index.html -Raw

# Replace placeholders
$content = $content -replace "__URL_PERSONALIZED_LEARNING_PATH__", $LEARNING_PATH_URL
$content = $content -replace "__URL_AI_MUSIC_COACH__", $COACH_URL

# Write back
Set-Content frontend/index.html -Value $content -NoNewline

Write-Host ""
Write-Host "📤 Uploading frontend to S3..." -ForegroundColor Yellow
aws s3 sync frontend/ s3://$BUCKET_NAME/ --cache-control no-cache --delete --region ap-southeast-1

Write-Host ""
Write-Host "🎉 Deployment completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "📋 Deployment Summary:" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Website URL:"
Write-Host "   $WEBSITE_URL" -ForegroundColor Yellow
Write-Host ""
Write-Host "🔗 API Endpoints:"
Write-Host "   Learning Path: $LEARNING_PATH_URL"
Write-Host "   AI Coach: $COACH_URL"
Write-Host ""
Write-Host "📦 S3 Bucket: $BUCKET_NAME"
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎵 Open the website URL in your browser to start using the app!" -ForegroundColor Green
Write-Host ""

# Restore original frontend file
if (Test-Path frontend/index.html.backup) {
    Move-Item frontend/index.html.backup frontend/index.html -Force
}
