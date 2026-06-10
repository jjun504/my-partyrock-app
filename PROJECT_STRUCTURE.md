# 📁 Project Structure

Complete overview of the AI Music Learning Companion project structure.

## Directory Tree

```
ai-music-learning-companion/
├── .github/
│   └── workflows/
│       └── deploy.yml                 # GitHub Actions CI/CD pipeline
├── backend/
│   ├── personalized_learning_path/
│   │   ├── app.py                     # Flask app for learning path generation
│   │   ├── requirements.txt           # Python dependencies
│   │   └── run.sh                     # Startup script for Lambda
│   └── ai_music_coach/
│       ├── app.py                     # Flask app for AI chat coach
│       ├── requirements.txt           # Python dependencies
│       └── run.sh                     # Startup script for Lambda
├── frontend/
│   └── index.html                     # Single-page application (HTML/CSS/JS)
├── infra/
│   └── template.yaml                  # AWS SAM infrastructure template
├── .gitignore                         # Git ignore patterns
├── README.md                          # Project documentation
├── DEPLOYMENT_GUIDE.md                # Step-by-step deployment instructions
├── PROJECT_STRUCTURE.md               # This file
├── quick-deploy.sh                    # Bash deployment script (Linux/macOS)
└── quick-deploy.ps1                   # PowerShell deployment script (Windows)
```

## File Descriptions

### GitHub Actions

#### `.github/workflows/deploy.yml`
- **Purpose**: Automated CI/CD pipeline for AWS deployment
- **Triggers**: Push to main branch or manual workflow dispatch
- **Steps**:
  1. Checkout code
  2. Configure AWS credentials
  3. Setup Python and SAM CLI
  4. Build SAM application
  5. Deploy to AWS
  6. Inject Lambda URLs into frontend
  7. Upload frontend to S3

### Backend

#### `backend/personalized_learning_path/app.py`
- **Purpose**: Lambda function for generating personalized learning paths
- **Framework**: Flask with streaming support
- **Model**: Claude Sonnet 4.6 via Amazon Bedrock
- **Input**: Instrument, skill level, genre preferences
- **Output**: Streaming text response with curriculum
- **Key Features**:
  - Real-time streaming with `invoke_model_with_response_stream`
  - CORS headers for cross-origin requests
  - Error handling and response formatting

#### `backend/personalized_learning_path/requirements.txt`
- **Dependencies**:
  - `flask>=3.0.0` - Web framework
  - `boto3>=1.34.0` - AWS SDK for Python

#### `backend/personalized_learning_path/run.sh`
- **Purpose**: Entrypoint script for Lambda
- **Content**: Starts Flask application

#### `backend/ai_music_coach/app.py`
- **Purpose**: Lambda function for AI chat coach
- **Framework**: Flask with streaming support
- **Model**: Claude Sonnet 4.6 via Amazon Bedrock
- **Input**: User message, conversation history, learning path context
- **Output**: Streaming chat responses
- **Key Features**:
  - Maintains conversation context
  - System prompt with user profile
  - Real-time token streaming

#### `backend/ai_music_coach/requirements.txt`
- **Dependencies**: Same as learning path function

#### `backend/ai_music_coach/run.sh`
- **Purpose**: Entrypoint script for Lambda

### Frontend

#### `frontend/index.html`
- **Purpose**: Single-page application UI
- **Technology**: Pure HTML/CSS/JavaScript (no frameworks)
- **Features**:
  - Responsive design (mobile and desktop)
  - Real-time streaming with Fetch API + ReadableStream
  - Markdown rendering with fade-in animations
  - Chat interface with conversation history
  - Loading states and error handling
- **URL Injection**: Placeholders replaced by GitHub Actions:
  - `__URL_PERSONALIZED_LEARNING_PATH__`
  - `__URL_AI_MUSIC_COACH__`

### Infrastructure

#### `infra/template.yaml`
- **Purpose**: AWS SAM template for infrastructure as code
- **Resources**:
  - **AppBedrockRole**: IAM role with Bedrock permissions
  - **PersonalizedLearningPathFunction**: Lambda for learning path generation
  - **AIMusicCoachFunction**: Lambda for AI chat coach
  - **FrontendBucket**: S3 bucket for static website hosting
  - **FrontendBucketPolicy**: Public read access for website files
- **Outputs**:
  - Lambda Function URLs
  - S3 website URL
  - Bucket name

### Configuration

#### `.gitignore`
- **Purpose**: Exclude files from version control
- **Patterns**:
  - AWS SAM build artifacts (`.aws-sam/`)
  - Python cache and virtual environments
  - Environment variables (`.env`)
  - IDE settings
  - OS-specific files

### Documentation

#### `README.md`
- **Purpose**: Main project documentation
- **Contents**:
  - Overview and features
  - Architecture description
  - Pre-deployment checklist
  - Usage instructions
  - Tech stack details
  - Cost estimation

#### `DEPLOYMENT_GUIDE.md`
- **Purpose**: Detailed deployment instructions
- **Contents**:
  - Step-by-step deployment process
  - AWS Bedrock model access setup
  - GitHub secrets configuration
  - Troubleshooting guide
  - Resource cleanup instructions

#### `PROJECT_STRUCTURE.md`
- **Purpose**: This file - project structure documentation

### Deployment Scripts

#### `quick-deploy.sh`
- **Purpose**: Automated deployment for Linux/macOS
- **Language**: Bash
- **Features**:
  - Prerequisites check
  - Interactive prompts
  - SAM build and deploy
  - Frontend URL injection
  - S3 upload
  - Summary output

#### `quick-deploy.ps1`
- **Purpose**: Automated deployment for Windows
- **Language**: PowerShell
- **Features**: Same as bash script

## Key Technologies

### Frontend
- **HTML5**: Semantic markup
- **CSS3**: Modern styling with gradients, animations, flexbox
- **JavaScript (ES6+)**: 
  - Fetch API for HTTP requests
  - ReadableStream for streaming responses
  - DOM manipulation
  - Event handling

### Backend
- **Python 3.12**: Runtime environment
- **Flask 3.0+**: Web framework
- **Boto3**: AWS SDK
- **Lambda Web Adapter**: HTTP server to Lambda adapter

### Infrastructure
- **AWS Lambda**: Serverless compute
- **Amazon Bedrock**: AI model hosting
- **S3**: Static website hosting
- **IAM**: Access management
- **CloudFormation**: Infrastructure provisioning (via SAM)

### CI/CD
- **GitHub Actions**: Automated deployment
- **AWS SAM**: Build and deployment tool

## Data Flow

### Learning Path Generation
1. User fills form (instrument, skill level, genre)
2. Frontend sends POST to Lambda Function URL
3. Lambda invokes Bedrock with streaming
4. Bedrock streams tokens back to Lambda
5. Lambda streams to frontend via HTTP
6. Frontend renders markdown line-by-line

### AI Coach Chat
1. User types message and clicks send
2. Frontend builds payload with conversation history
3. POST to AI Coach Lambda Function URL
4. Lambda builds prompt with system context
5. Bedrock streams response
6. Frontend renders in chat bubble with streaming effect
7. Frontend updates conversation history

## Security Considerations

### IAM Permissions
- Lambda functions use least-privilege IAM role
- Only Bedrock invoke permissions granted
- No overly broad wildcards

### CORS
- All Lambda responses include CORS headers
- Allows requests from any origin (public app)
- Production apps should restrict origins

### API Access
- Lambda Function URLs are public (AuthType: NONE)
- No authentication required
- Production apps should add auth layer

### S3 Bucket
- Public read access for website hosting
- No write access from public
- Objects served via HTTP/HTTPS

## Cost Optimization

### Lambda
- Response streaming reduces buffering memory
- 256 MB memory allocation (balance cost/performance)
- 60-second timeout (adequate for AI responses)

### Bedrock
- Global inference profile for best pricing/latency
- Streaming reduces time-to-first-token
- Token usage is primary cost driver

### S3
- `cache-control: no-cache` ensures fresh content
- Minimal storage costs (single HTML file)
- Low bandwidth for static assets

## Future Enhancements

Potential improvements for production:

1. **Authentication**: Add Cognito user pools
2. **Persistence**: Store conversations in DynamoDB
3. **Custom Domain**: CloudFront + Route 53
4. **Monitoring**: CloudWatch dashboards and alarms
5. **Rate Limiting**: API Gateway + WAF
6. **Multi-region**: CloudFront edge locations
7. **A/B Testing**: Multiple model versions
8. **Analytics**: User interaction tracking
9. **Feedback Loop**: Rating system for responses
10. **Mobile App**: React Native wrapper

---

For questions or contributions, please refer to the main README.md
