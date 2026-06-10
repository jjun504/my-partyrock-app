# 🏗️ Architecture Diagram - AI Music Learning Companion

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER BROWSER                             │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              frontend/index.html (S3)                      │ │
│  │                                                            │ │
│  │  • Form inputs (instrument, skill, genre)                 │ │
│  │  • Streaming text output (learning path)                  │ │
│  │  • Chat interface (AI coach)                              │ │
│  │  • Real-time markdown rendering                           │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
└──────────┬────────────────────────────────────┬────────────────┘
           │                                    │
           │ POST /                             │ POST /
           │ (streaming)                        │ (streaming)
           │                                    │
┌──────────▼──────────────────┐   ┌────────────▼────────────────┐
│  Lambda Function URL        │   │  Lambda Function URL        │
│  (PersonalizedLearningPath) │   │  (AIMusicCoach)             │
│                             │   │                             │
│  ┌───────────────────────┐  │   │  ┌───────────────────────┐  │
│  │ Flask App (app.py)    │  │   │  │ Flask App (app.py)    │  │
│  │                       │  │   │  │                       │  │
│  │ • Receives user data  │  │   │  │ • Receives chat msg   │  │
│  │ • Builds prompt       │  │   │  │ • Builds conversation │  │
│  │ • Calls Bedrock       │  │   │  │ • Calls Bedrock       │  │
│  │ • Streams response    │  │   │  │ • Streams response    │  │
│  └───────────┬───────────┘  │   │  └───────────┬───────────┘  │
│              │              │   │              │              │
└──────────────┼──────────────┘   └──────────────┼──────────────┘
               │                                 │
               │ invoke_model_with_              │
               │ response_stream                 │
               │                                 │
        ┌──────▼─────────────────────────────────▼──────┐
        │         Amazon Bedrock                        │
        │                                               │
        │  ┌─────────────────────────────────────────┐  │
        │  │  Claude Sonnet 4.6                      │  │
        │  │  (global inference profile)             │  │
        │  │                                         │  │
        │  │  • Generates curriculum                 │  │
        │  │  • Provides coaching responses          │  │
        │  │  • Streams tokens in real-time          │  │
        │  └─────────────────────────────────────────┘  │
        │                                               │
        └───────────────────────────────────────────────┘
```

---

## Data Flow - Learning Path Generation

```
1. USER ACTION
   └─> User fills form (Guitar, Intermediate, Jazz)
   └─> Clicks "Generate My Learning Path"

2. FRONTEND
   └─> Creates JSON payload: {instrument, skill_level, genre}
   └─> POST to Lambda Function URL (streaming)
   └─> Starts reading response stream

3. LAMBDA FUNCTION (PersonalizedLearningPath)
   └─> Receives POST request
   └─> Extracts form data
   └─> Builds AI prompt with user context
   └─> Calls Bedrock: invoke_model_with_response_stream()

4. AMAZON BEDROCK
   └─> Routes to Claude Sonnet 4.6 (global profile)
   └─> Generates personalized curriculum
   └─> Streams tokens back to Lambda

5. LAMBDA RESPONSE
   └─> Receives token stream from Bedrock
   └─> Yields each token via Flask stream_with_context()
   └─> Adds CORS headers

6. FRONTEND RENDERING
   └─> Reads stream with ReadableStream.getReader()
   └─> Decodes chunks with TextDecoder
   └─> Parses markdown per line
   └─> Renders with fade-in animation
   └─> Shows blinking cursor on active line

7. COMPLETION
   └─> Full learning path displayed
   └─> Chat interface enabled
   └─> User can ask questions
```

---

## Data Flow - AI Coach Chat

```
1. USER ACTION
   └─> Types message: "What should I practice first?"
   └─> Clicks "Send"

2. FRONTEND
   └─> Adds user message to chat UI
   └─> Creates payload with:
       • Current message
       • Conversation history
       • User profile (instrument, level, genre)
       • Learning path content
   └─> POST to AI Coach Lambda URL

3. LAMBDA FUNCTION (AIMusicCoach)
   └─> Receives POST with full context
   └─> Builds system prompt with user profile
   └─> Creates messages array with history
   └─> Calls Bedrock with streaming

4. AMAZON BEDROCK
   └─> Generates contextual response
   └─> Considers user's instrument and level
   └─> References learning path content
   └─> Streams response tokens

5. LAMBDA RESPONSE
   └─> Streams tokens back to frontend
   └─> Maintains CORS headers

6. FRONTEND RENDERING
   └─> Creates assistant message bubble
   └─> Streams tokens into bubble
   └─> Renders markdown formatting
   └─> Updates conversation history array

7. COMPLETION
   └─> Full response displayed
   └─> User can send another message
   └─> Context maintained for next question
```

---

## Deployment Flow

```
┌────────────────────────────────────────────────────────┐
│                   DEVELOPER                            │
│                                                        │
│  git push origin main                                  │
└────────────┬───────────────────────────────────────────┘
             │
             │ trigger
             │
┌────────────▼───────────────────────────────────────────┐
│              GITHUB ACTIONS                            │
│                                                        │
│  1. Checkout code                                      │
│  2. Configure AWS credentials                          │
│  3. Setup Python + SAM CLI                             │
│  4. sam build --template infra/template.yaml           │
│  5. sam deploy (creates/updates stack)                 │
│  6. Get CloudFormation outputs (Lambda URLs)           │
│  7. Inject URLs into frontend/index.html               │
│  8. aws s3 sync frontend/ to bucket                    │
└────────────┬───────────────────────────────────────────┘
             │
             │ creates/updates
             │
┌────────────▼───────────────────────────────────────────┐
│           AWS CLOUDFORMATION                           │
│                                                        │
│  Stack: ai-music-learning-companion                    │
│                                                        │
│  Resources Created:                                    │
│  • IAM Role (AppBedrockRole)                           │
│  • Lambda: PersonalizedLearningPathFunction            │
│  • Lambda: AIMusicCoachFunction                        │
│  • Lambda Function URLs (streaming enabled)            │
│  • S3 Bucket (static website hosting)                  │
│  • S3 Bucket Policy (public read)                      │
│                                                        │
│  Outputs:                                              │
│  • PersonalizedLearningPathUrl                         │
│  • AIMusicCoachUrl                                     │
│  • WebsiteUrl                                          │
│  • BucketName                                          │
└────────────────────────────────────────────────────────┘
```

---

## AWS Services Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS CLOUD                            │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  S3 BUCKET (Static Website)                      │   │
│  │                                                  │   │
│  │  • Public read access                            │   │
│  │  • Website hosting enabled                       │   │
│  │  • Serves frontend/index.html                    │   │
│  │  • Cache-control: no-cache                       │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  LAMBDA FUNCTIONS (Python 3.12)                  │   │
│  │                                                  │   │
│  │  ┌────────────────────────────────────────────┐  │   │
│  │  │ PersonalizedLearningPathFunction           │  │   │
│  │  │ • Flask app with Lambda Web Adapter        │  │   │
│  │  │ • Response streaming enabled               │  │   │
│  │  │ • 256 MB memory, 60s timeout               │  │   │
│  │  │ • Function URL (no auth)                   │  │   │
│  │  └────────────────────────────────────────────┘  │   │
│  │                                                  │   │
│  │  ┌────────────────────────────────────────────┐  │   │
│  │  │ AIMusicCoachFunction                       │  │   │
│  │  │ • Flask app with Lambda Web Adapter        │  │   │
│  │  │ • Response streaming enabled               │  │   │
│  │  │ • 256 MB memory, 60s timeout               │  │   │
│  │  │ • Function URL (no auth)                   │  │   │
│  │  └────────────────────────────────────────────┘  │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  IAM ROLE (AppBedrockRole)                       │   │
│  │                                                  │   │
│  │  Permissions:                                    │   │
│  │  • AWSLambdaBasicExecutionRole                   │   │
│  │  • bedrock:InvokeModel                           │   │
│  │  • bedrock:InvokeModelWithResponseStream         │   │
│  │                                                  │   │
│  │  Resources:                                      │   │
│  │  • global.anthropic.claude-sonnet-4-6-*          │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
│  ┌──────────────────────────────────────────────────┐   │
│  │  AMAZON BEDROCK                                  │   │
│  │                                                  │   │
│  │  Model: Claude Sonnet 4.6                        │   │
│  │  Profile: global inference (worldwide routing)   │   │
│  │  Streaming: Enabled                              │   │
│  │  Region: ap-southeast-1 (configurable)           │   │
│  └──────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## Request/Response Flow Detail

```
┌─────────────────────────────────────────────────────────┐
│ 1. HTTP POST REQUEST                                    │
└─────────────────────────────────────────────────────────┘
   URL: https://xxx.lambda-url.ap-southeast-1.on.aws/
   Method: POST
   Headers:
     Content-Type: application/json
   Body:
     {
       "instrument": "Guitar",
       "skill_level": "Intermediate",
       "genre": "Jazz, Blues"
     }

┌─────────────────────────────────────────────────────────┐
│ 2. LAMBDA PROCESSING                                    │
└─────────────────────────────────────────────────────────┘
   • Lambda Web Adapter converts HTTP → Flask
   • Flask route receives POST request
   • Extract JSON payload
   • Build prompt for Bedrock

┌─────────────────────────────────────────────────────────┐
│ 3. BEDROCK API CALL                                     │
└─────────────────────────────────────────────────────────┘
   bedrock_runtime.invoke_model_with_response_stream(
     modelId='global.anthropic.claude-sonnet-4-6-20260217-v1:0',
     body={
       "anthropic_version": "bedrock-2023-05-31",
       "max_tokens": 4000,
       "messages": [
         {
           "role": "user",
           "content": "Based on the user's instrument..."
         }
       ],
       "temperature": 0.7
     }
   )

┌─────────────────────────────────────────────────────────┐
│ 4. STREAMING RESPONSE                                   │
└─────────────────────────────────────────────────────────┘
   stream = response.get('body')
   for event in stream:
     chunk = event.get('chunk')
     chunk_obj = json.loads(chunk.get('bytes'))
     if chunk_obj['type'] == 'content_block_delta':
       text = chunk_obj['delta']['text']
       yield text  # Stream to frontend

┌─────────────────────────────────────────────────────────┐
│ 5. HTTP STREAMING RESPONSE                              │
└─────────────────────────────────────────────────────────┘
   Status: 200 OK
   Headers:
     Content-Type: text/plain; charset=utf-8
     Access-Control-Allow-Origin: *
     Transfer-Encoding: chunked
   Body: (streaming)
     "Here"
     " is"
     " your"
     " personalized"
     " learning"
     " path"
     "..."

┌─────────────────────────────────────────────────────────┐
│ 6. FRONTEND STREAM PROCESSING                           │
└─────────────────────────────────────────────────────────┘
   const reader = response.body.getReader();
   const decoder = new TextDecoder();
   
   while (true) {
     const {done, value} = await reader.read();
     if (done) break;
     
     const text = decoder.decode(value);
     renderMarkdown(text);
     showFadeInAnimation();
   }
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────────┐
│  PUBLIC INTERNET                                        │
└───────────────┬─────────────────────────────────────────┘
                │
                │ HTTPS only
                │
        ┌───────▼────────┐
        │  CloudFront    │  (Optional - not included)
        │  + WAF         │  (For production hardening)
        └───────┬────────┘
                │
    ┌───────────┴────────────┐
    │                        │
┌───▼──────────┐    ┌────────▼────────┐
│   S3 Bucket  │    │ Lambda URLs     │
│   (Public)   │    │ (Public)        │
└──────────────┘    └────────┬────────┘
                             │
                    ┌────────▼────────┐
                    │  Lambda IAM     │
                    │  Execution Role │
                    └────────┬────────┘
                             │
                   ┌─────────▼──────────┐
                   │  Amazon Bedrock    │
                   │  (IAM Controlled)  │
                   └────────────────────┘

Security Layers:
1. S3: Public read only (no write)
2. Lambda: No authentication (public endpoint)
3. IAM: Least privilege for Bedrock access
4. Bedrock: AWS managed service security

Production Recommendations:
• Add Cognito authentication
• Add API Gateway + WAF
• Enable CloudTrail logging
• Set up billing alerts
• Implement rate limiting
```

---

## Cost Architecture

```
┌─────────────────────────────────────────────────────────┐
│  COST BREAKDOWN (per conversation)                      │
└─────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ Amazon Bedrock                                         │
│ • ~3000-5000 tokens per learning path                  │
│ • ~500-1000 tokens per chat exchange                   │
│ • $0.003 per 1K input tokens                           │
│ • $0.015 per 1K output tokens                          │
│ • Cost per learning path: ~$0.05-$0.08                 │
│ • Cost per chat: ~$0.01-$0.02                          │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ AWS Lambda                                             │
│ • 2 invocations per full conversation                  │
│ • ~10-30 seconds execution per invocation              │
│ • 256 MB memory allocation                             │
│ • $0.0000166667 per GB-second                          │
│ • Cost per conversation: ~$0.005                       │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ S3                                                     │
│ • Static file storage: ~100 KB                         │
│ • Data transfer: ~100 KB per visit                     │
│ • $0.023 per GB storage                                │
│ • $0.09 per GB transfer                                │
│ • Cost per month: ~$0.10 (fixed)                       │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ TOTAL COST ESTIMATE                                    │
│                                                        │
│ 100 conversations/month:                               │
│ • Bedrock: $10-15                                      │
│ • Lambda: $0.50                                        │
│ • S3: $0.10                                            │
│ • Total: ~$10-20/month                                 │
│                                                        │
│ 1000 conversations/month:                              │
│ • Bedrock: $100-150                                    │
│ • Lambda: $5                                           │
│ • S3: $0.50                                            │
│ • Total: ~$100-160/month                               │
└────────────────────────────────────────────────────────┘
```

---

## Scaling Architecture

```
┌─────────────────────────────────────────────────────────┐
│  USER TRAFFIC                                           │
└─────────────────────────────────────────────────────────┘
   1 user/sec ────────┐
   10 users/sec ──────┼─> Auto-scales transparently
   100 users/sec ─────┼─> No configuration needed
   1000 users/sec ────┘

┌─────────────────────────────────────────────────────────┐
│  S3 (Static Frontend)                                   │
│  • Unlimited concurrent requests                        │
│  • No scaling configuration needed                      │
│  • Global edge network (via CloudFront, optional)       │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Lambda Functions                                       │
│  • Auto-scales from 0 to thousands of instances         │
│  • Default: 1000 concurrent executions per region       │
│  • Can request increase via AWS Support                 │
│  • No manual intervention required                      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  Amazon Bedrock                                         │
│  • Global inference profile for load distribution       │
│  • Routes to best available region automatically        │
│  • Handles burst traffic                                │
│  • Quotas can be increased via AWS Support              │
└─────────────────────────────────────────────────────────┘

Scaling Characteristics:
• Scales from 0 to thousands of users automatically
• No provisioning or configuration needed
• Pay only for actual usage
• No idle costs when not in use
• Global distribution for low latency
```

---

## Technology Stack Diagram

```
┌─────────────────────────────────────────────────────────┐
│  FRONTEND STACK                                         │
├─────────────────────────────────────────────────────────┤
│  • HTML5                                                │
│  • CSS3 (Flexbox, Grid, Animations)                     │
│  • JavaScript ES6+ (Async/Await, Fetch API)             │
│  • ReadableStream API (Streaming)                       │
│  • TextDecoder API (UTF-8 decoding)                     │
│  • DOM Manipulation (Native)                            │
│  • Markdown Parsing (Custom implementation)             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  BACKEND STACK                                          │
├─────────────────────────────────────────────────────────┤
│  • Python 3.12                                          │
│  • Flask 3.0+ (Web framework)                           │
│  • Boto3 (AWS SDK)                                      │
│  • Lambda Web Adapter (HTTP bridge)                     │
│  • JSON (Data serialization)                            │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  INFRASTRUCTURE STACK                                   │
├─────────────────────────────────────────────────────────┤
│  • AWS SAM (Serverless Application Model)               │
│  • CloudFormation (Infrastructure as Code)              │
│  • Lambda (Compute)                                     │
│  • S3 (Storage)                                         │
│  • IAM (Security)                                       │
│  • Bedrock (AI)                                         │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  CI/CD STACK                                            │
├─────────────────────────────────────────────────────────┤
│  • GitHub Actions (CI/CD platform)                      │
│  • AWS CLI (Deployment)                                 │
│  • SAM CLI (Build & Deploy)                             │
│  • Bash/sed (URL injection)                             │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  AI STACK                                               │
├─────────────────────────────────────────────────────────┤
│  • Amazon Bedrock (AI Platform)                         │
│  • Claude Sonnet 4.6 (LLM)                              │
│  • Anthropic API (via Bedrock)                          │
│  • Response Streaming (Token-by-token)                  │
│  • Global Inference Profile (Worldwide routing)         │
└─────────────────────────────────────────────────────────┘
```

---

This architecture is designed for:
✅ Scalability - Auto-scales with traffic
✅ Performance - Streaming responses, global routing
✅ Cost-efficiency - Pay-per-use, no idle costs
✅ Simplicity - Serverless, no server management
✅ Security - IAM roles, HTTPS, least privilege
✅ Maintainability - Infrastructure as code, automated deployment

**Ready to deploy? → [START_HERE.md](START_HERE.md)**
