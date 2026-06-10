import json
import boto3
import os
from flask import Flask, request, Response, stream_with_context

app = Flask(__name__)

bedrock_runtime = boto3.client(
    service_name='bedrock-runtime',
    region_name='ap-southeast-1'
)

MODEL_ID = 'anthropic.claude-3-5-sonnet-20241022-v2:0'

def generate_stream(instrument, skill_level, genre):
    prompt = f"""Based on the user's instrument {instrument}, skill level {skill_level}, and genre preferences {genre}, design a tailored musical learning curriculum that includes specific techniques, chord progressions, and practice strategies."""

    body = {
        "anthropic_version": "bedrock-2023-05-31",
        "max_tokens": 4000,
        "messages": [
            {
                "role": "user",
                "content": prompt
            }
        ],
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
    return {'status': 'healthy', 'service': 'personalized_learning_path'}, 200

@app.route('/', methods=['POST', 'OPTIONS'])
def handle_request():
    if request.method == 'OPTIONS':
        return '', 200

    try:
        data = request.get_json()
        instrument = data.get('instrument', '')
        skill_level = data.get('skill_level', '')
        genre = data.get('genre', '')

        def generate():
            try:
                for chunk in generate_stream(instrument, skill_level, genre):
                    yield chunk
            except Exception as e:
                yield f"Error: {str(e)}"

        return Response(stream_with_context(generate()), content_type='text/plain; charset=utf-8')

    except Exception as e:
        return Response(f"Error: {str(e)}", content_type='text/plain; charset=utf-8', status=500)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
