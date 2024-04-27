#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if a file path was provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_json_file>"
    exit 1
fi

# Read the JSON file from the first argument and encode it in base64
PAYLOAD=$(cat "$1" | openssl base64)

# Test the Lambda function
aws lambda invoke \
    --function-name llnIntelligenceLambda \
    --payload "$PAYLOAD" response.json \
    --profile lln-profile

# Print the contents of the response
echo "Lambda function response:"
cat response.json
echo ""