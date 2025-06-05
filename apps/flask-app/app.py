from flask import Flask, request, jsonify
import boto3
import os
import time

app = Flask(__name__)

# AWS clients
ssm = boto3.client('ssm', region_name=os.getenv('AWS_REGION', 'us-west-2'))
sqs = boto3.client('sqs', region_name=os.getenv('AWS_REGION', 'us-west-2'))
# TODO: change the usage of the environment variable from .env to ECS task definition
# Environment variables (set these in your ECS task or .env for local dev)
SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL')
TOKEN_PARAM_NAME = os.getenv('TOKEN_PARAM_NAME', '/checkpoint/dev/token')

def get_token_from_ssm():
    response = ssm.get_parameter(Name=TOKEN_PARAM_NAME, WithDecryption=True)
    return response['Parameter']['Value']

@app.route('/email', methods=['POST'])
def handle_email():
    data = request.get_json() # Payload validation
    if not data or 'token' not in data or 'data' not in data:
        return jsonify({'error': 'Invalid payload'}), 400

    # Validate token
    try:
        expected_token = get_token_from_ssm()
    except Exception as e:
        return jsonify({'error': 'Token retrieval failed', 'details': str(e)}), 500

    if data['token'] != expected_token:
        return jsonify({'error': 'Invalid token'}), 401

    # Validate email_timestream
    email_data = data['data']
    if 'email_timestream' not in email_data:
        return jsonify({'error': 'Missing email_timestream'}), 400
    try:
        ts = int(email_data['email_timestream'])
        # Optionally, check if timestamp is within a reasonable range
        if ts < 0 or ts > int(time.time()) + 60*60*24*365:
            return jsonify({'error': 'Invalid email_timestream'}), 400
    except Exception:
        return jsonify({'error': 'Invalid email_timestream format'}), 400

    # Publish to SQS
    try:
        sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=request.data.decode('utf-8')
        )
    except Exception as e:
        return jsonify({'error': 'Failed to publish to SQS', 'details': str(e)}), 500

    return jsonify({'message': 'Email received and queued'}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)