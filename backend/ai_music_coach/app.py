import json
import boto3
import os
from flask import Flask, request, Response, stream_with_context

app = Flask(__name__)

bedrock_runtime = boto3.client(
    service_name='bedrock-runtime',
    region_name='ap-southeast-1'
)

MODEL_ID = 'anthropic.claude-sonnet-4-6'

def generate_stream(skill_level, instrument, genre, learning_path, message, conversation_history):
    system_prompt = f"""I'm a {skill_level} {instrument} player interested in {genre}. Help me understand my personalized learning path: {learning_path}"""

    messages = []
    
    # Add conversation history
    for msg in conversation_history:
        messages.append({
            "role": msg["role"],
            "content": msg["content"]
        })

    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4000,
        "system": system_prompt,
        "messages": messages,
        "temperature": 0.7
    }

    response = bedrock_runtime.invoke_model_with_response_stream(
        modelId=MODEL_ID,
        body=json.dumps(body)
    )

    stream = response.get('body')
    if stream:
        for event in stream:
            chunk = event.get('chunk')
            if chunk:
                chunk_obj = json.loads(chunk.get('bytes').decode())
                
                if chunk_obj['type'] == 'content_block_delta':
                    if chunk_obj['delta']['type'] == 'text_delta':
                        yield chunk_obj['delta']['text']

@app.after_request
def after_request(response):
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    return response

@app.route('/', methods=['GET'])
def health_check():
    return {'status': 'healthy', 'service': 'ai_music_coach'}, 200

@app.route('/', methods=['POST', 'OPTIONS'])
def handle_request():
    if request.method == 'OPTIONS':
        return '', 200

    try:
        data = request.get_json()
        skill_level = data.get('skill_level', '')
        instrument = data.get('instrument', '')
        genre = data.get('genre', '')
        learning_path = data.get('learning_path', '')
        message = data.get('message', '')
        conversation_history = data.get('conversation_history', [])

        def generate():
            try:
                for chunk in generate_stream(skill_level, instrument, genre, learning_path, message, conversation_history):
                    yield chunk
            except Exception as e:
                yield f"Error: {str(e)}"

        return Response(stream_with_context(generate()), content_type='text/plain; charset=utf-8')

    except Exception as e:
        return Response(f"Error: {str(e)}", content_type='text/plain; charset=utf-8', status=500)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
