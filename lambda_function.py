import argparse
import json
import logging

# Initialize logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):

    # Log the message
    print(f'Received event: {event}')

    # Return the message
    return {
        'statusCode': 200,
        'body': f"Success: {event}"
    }


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