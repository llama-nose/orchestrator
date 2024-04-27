import argparse
import json
import logging
import boto3
import uuid

from datetime import datetime

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

dynamodb = boto3.resource('dynamodb')
lambda_client = boto3.client('lambda', region_name='us-east-2')
function_arn = 'arn:aws:lambda:us-east-2:158267493868:function:llnMuleLambda'

def handler(event, context):
    # unpack events
    user_id = event['user_id']
    llm_metadata = event['llm_metadata']
    system_msg = event['system_msg']
    user_msg = event['user_msg']
    n = event['n']
    session_id = str(uuid.uuid4())

    # contruct llm_msg
    llm_msg = construct_llm_msg(system_msg, user_msg)

    # call mule X times
    call_mule(user_id, session_id, llm_metadata, llm_msg, n)
    
    # write to dynamo
    response_ids = []
    write_to_dynamo(user_id, session_id, response_ids, llm_metadata)

    # Return the message
    return {
        'statusCode': 200,
        'body': f"Success: yoyoyo"
    }

def call_mule(user_id, session_id, llm_metadata, llm_msg, n):
    payload = {
            "user_id": user_id,
            "session_id": session_id,
            "llm_metadata": llm_metadata,
            "llm_msg": llm_msg,
        }
    payload_bytes = json.dumps(payload).encode('utf-8')

    response_ids = []

    for _ in range(n):
        response_id = str(uuid.uuid4())
        payload['response_id'] = response_id
        response = lambda_client.invoke(
            FunctionName=function_arn,
            InvocationType='Event',  # This specifies asynchronous execution
            Payload = payload_bytes
        )
        response_id.append(response_id)

    return

def write_to_dynamo(user_id, session_id, response_ids, llm_metadata):
    current_timestamp = datetime.utcnow().isoformat()

    table = dynamodb.Table('session')
    table.put_item(
        Item={
            'id': session_id,
            'user_id': user_id,
            'response_ids': response_ids,
            'llm_metadata': llm_metadata,
            'created_at': current_timestamp,
            'updated_at': current_timestamp
        }
    )

    return

def construct_llm_msg(system_msg, user_msg):
    llm_msg = []

    for i in range(len(system_msg)):
        llm_msg.append({
            "role": "system",
            "content": system_msg
        })

        llm_msg.append({
            "role": "user",
            "content": user_msg
        })

    return llm_msg

def parse_args():
    parser = argparse.ArgumentParser(description='Llama Nose Intelligence Lambda Function.')
    parser.add_argument('--test', type=str, required=True, help='Path to test JSON.')
    return parser.parse_args()


if __name__ == '__main__':
    # Test the handler
    args = parse_args()

    # Load the test JSON
    with open(args.test, 'r') as f:
        event = json.load(f)

    context = None
    print(handler(event, context))