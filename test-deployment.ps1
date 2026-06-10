# Test Deployment Script for AI Music Learning Companion
# This script verifies that all components are working correctly

$ErrorActionPreference = "Stop"

Write-Host "🧪 AI Music Learning Companion - Deployment Test" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Get stack outputs
Write-Host "📤 Retrieving stack information..." -ForegroundColor Yellow

function Get-StackOutput {
    param($OutputKey)
    
    try {
        $output = aws cloudformation describe-stacks `
            --stack-name ai-music-learning-companion `
            --query "Stacks[0].Outputs[?OutputKey=='$OutputKey'].OutputValue" `
            --output text `
            --region ap-southeast-1 2>$null
        
        if ([string]::IsNullOrWhiteSpace($output)) {
            return $null
        }
        return $output
    }
    catch {
        return $null
    }
}

$LEARNING_PATH_URL = Get-StackOutput "PersonalizedLearningPathUrl"
$COACH_URL = Get-StackOutput "AIMusicCoachUrl"
$WEBSITE_URL = Get-StackOutput "WebsiteUrl"
$BUCKET_NAME = Get-StackOutput "BucketName"

if (-not $LEARNING_PATH_URL -or -not $COACH_URL -or -not $WEBSITE_URL -or -not $BUCKET_NAME) {
    Write-Host "❌ Could not retrieve stack outputs. Is the stack deployed?" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Stack found and outputs retrieved" -ForegroundColor Green
Write-Host ""

# Test 1: Check Lambda Function URLs
Write-Host "🔍 Test 1: Lambda Function URLs" -ForegroundColor Yellow
Write-Host "   Learning Path URL: $LEARNING_PATH_URL"
Write-Host "   AI Coach URL: $COACH_URL"

if ($LEARNING_PATH_URL -match "^https://.*\.lambda-url\..*\.amazonaws\.com/$") {
    Write-Host "   ✅ Learning Path URL format is valid" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  Learning Path URL format looks unusual" -ForegroundColor Red
}

if ($COACH_URL -match "^https://.*\.lambda-url\..*\.amazonaws\.com/$") {
    Write-Host "   ✅ AI Coach URL format is valid" -ForegroundColor Green
} else {
    Write-Host "   ⚠️  AI Coach URL format looks unusual" -ForegroundColor Red
}
Write-Host ""

# Test 2: Check S3 Bucket
Write-Host "🔍 Test 2: S3 Bucket and Website" -ForegroundColor Yellow
Write-Host "   Bucket: $BUCKET_NAME"
Write-Host "   Website URL: $WEBSITE_URL"

try {
    $bucketExists = aws s3 ls s3://$BUCKET_NAME --region ap-southeast-1 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ S3 bucket exists and is accessible" -ForegroundColor Green
    } else {
        Write-Host "   ❌ Cannot access S3 bucket" -ForegroundColor Red
    }
}
catch {
    Write-Host "   ❌ Error checking S3 bucket: $_" -ForegroundColor Red
}

# Check if index.html exists
try {
    aws s3 ls s3://$BUCKET_NAME/index.html --region ap-southeast-1 > $null 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✅ index.html found in bucket" -ForegroundColor Green
    } else {
        Write-Host "   ❌ index.html not found in bucket" -ForegroundColor Red
        Write-Host "      Run the deployment script to upload the frontend" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "   ❌ Error checking index.html: $_" -ForegroundColor Red
}
Write-Host ""

# Test 3: Test Lambda Function - Learning Path (OPTIONS for CORS)
Write-Host "🔍 Test 3: Lambda CORS Headers" -ForegroundColor Yellow
Write-Host "   Testing OPTIONS request to Learning Path function..."

try {
    $response = Invoke-WebRequest -Uri $LEARNING_PATH_URL -Method OPTIONS -ErrorAction SilentlyContinue
    $corsHeader = $response.Headers['Access-Control-Allow-Origin']
    
    if ($corsHeader -eq '*') {
        Write-Host "   ✅ CORS headers are properly configured" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  CORS headers may not be properly configured" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "   ⚠️  Could not test CORS (this may be normal)" -ForegroundColor Yellow
}
Write-Host ""

# Test 4: Test Lambda Function - Actual Request
Write-Host "🔍 Test 4: Lambda Function Execution" -ForegroundColor Yellow
Write-Host "   Sending test request to Learning Path function..."
Write-Host "   (This will invoke Bedrock and may take 10-30 seconds)" -ForegroundColor Gray

$testPayload = @{
    instrument = "Guitar"
    skill_level = "Intermediate"
    genre = "Jazz"
} | ConvertTo-Json

try {
    $testResponse = Invoke-WebRequest -Uri $LEARNING_PATH_URL `
        -Method POST `
        -ContentType "application/json" `
        -Body $testPayload `
        -TimeoutSec 60 `
        -ErrorAction Stop
    
    if ($testResponse.StatusCode -eq 200) {
        $responseText = $testResponse.Content
        if ($responseText.Length -gt 100) {
            Write-Host "   ✅ Lambda function executed successfully" -ForegroundColor Green
            Write-Host "   ✅ Received streaming response ($($responseText.Length) characters)" -ForegroundColor Green
            Write-Host "   Preview: $($responseText.Substring(0, [Math]::Min(100, $responseText.Length)))..." -ForegroundColor Gray
        } else {
            Write-Host "   ⚠️  Response received but seems short" -ForegroundColor Yellow
        }
    } else {
        Write-Host "   ❌ Unexpected status code: $($testResponse.StatusCode)" -ForegroundColor Red
    }
}
catch {
    Write-Host "   ❌ Error testing Lambda function: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "   This could indicate:" -ForegroundColor Yellow
    Write-Host "   - Bedrock model access not enabled" -ForegroundColor Yellow
    Write-Host "   - IAM permissions issue" -ForegroundColor Yellow
    Write-Host "   - Lambda timeout or error" -ForegroundColor Yellow
}
Write-Host ""

# Test 5: Check IAM Role and Permissions
Write-Host "🔍 Test 5: IAM Configuration" -ForegroundColor Yellow

try {
    $stackResources = aws cloudformation describe-stack-resources `
        --stack-name ai-music-learning-companion `
        --region ap-southeast-1 2>$null | ConvertFrom-Json
    
    $roleResource = $stackResources.StackResources | Where-Object { $_.ResourceType -eq "AWS::IAM::Role" }
    
    if ($roleResource) {
        Write-Host "   ✅ IAM role found: $($roleResource.PhysicalResourceId)" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  Could not find IAM role in stack" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "   ⚠️  Could not verify IAM configuration" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "📋 Test Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌐 Access your application at:" -ForegroundColor Green
Write-Host "   $WEBSITE_URL" -ForegroundColor Yellow
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Open the website URL in your browser"
Write-Host "   2. Fill in the form with your preferences"
Write-Host "   3. Click 'Generate My Learning Path'"
Write-Host "   4. Chat with your AI music coach"
Write-Host ""
Write-Host "🐛 If you encounter issues:" -ForegroundColor Cyan
Write-Host "   - Check CloudWatch Logs for Lambda errors"
Write-Host "   - Verify Bedrock model access is enabled"
Write-Host "   - Review DEPLOYMENT_GUIDE.md troubleshooting section"
Write-Host ""
Write-Host "📊 View logs with:" -ForegroundColor Cyan
Write-Host '   sam logs --stack-name ai-music-learning-companion --name PersonalizedLearningPathFunction --region ap-southeast-1 --tail' -ForegroundColor Gray
Write-Host ""
