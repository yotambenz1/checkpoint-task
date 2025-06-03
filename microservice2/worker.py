import os
import time
import json
import boto3
from dotenv import load_dotenv

load_dotenv()

SQS_QUEUE_URL = os.getenv('SQS_QUEUE_URL')
S3_BUCKET = os.getenv('S3_BUCKET')
S3_PREFIX = os.getenv('S3_PREFIX', 'emails/')
POLL_INTERVAL = int(os.getenv('POLL_INTERVAL', '10'))  # seconds

sqs = boto3.client('sqs', region_name=os.getenv('AWS_REGION', 'us-east-1'))
s3 = boto3.client('s3', region_name=os.getenv('AWS_REGION', 'us-east-1'))

def process_message(message):
    body = message['Body']
    # Use messageId or timestamp for unique filename
    message_id = message['MessageId']
    filename = f'{S3_PREFIX}{message_id}.json'
    s3.put_object(Bucket=S3_BUCKET, Key=filename, Body=body)
    print(f"Uploaded message {message_id} to s3://{S3_BUCKET}/{filename}")

def main():
    print("Starting SQS to S3 worker...")
    while True:
        response = sqs.receive_message(
            QueueUrl=SQS_QUEUE_URL,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=10
        )
        messages = response.get('Messages', [])
        if not messages:
            print("No messages found. Sleeping...")
            time.sleep(POLL_INTERVAL)
            continue

        for message in messages:
            try:
                process_message(message)
                # Delete message after processing
                sqs.delete_message(
                    QueueUrl=SQS_QUEUE_URL,
                    ReceiptHandle=message['ReceiptHandle']
                )
            except Exception as e:
                print(f"Error processing message: {e}")

if __name__ == '__main__':
    main()