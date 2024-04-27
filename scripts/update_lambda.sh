#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Build Docker image
echo "[Step 1] Building Docker image..."
docker build \
  --build-arg GUARDRAILS_TOKEN=$(echo $GUARDRAILS_TOKEN) \
  --platform linux/amd64 \
  -t lln-intelligence:test .

# Login to AWS ECR
echo "[Step 2] Logging into AWS ECR..."
aws ecr get-login-password --region us-east-2 --profile lln-profile | docker login --username AWS --password-stdin 158267493868.dkr.ecr.us-east-2.amazonaws.com/lln-intelligence:latest

# Tag and push Docker image to ECR
echo "[Step 3] Tagging and pushing Docker image to ECR..."
docker tag lln-intelligence:test 158267493868.dkr.ecr.us-east-2.amazonaws.com/lln-intelligence:latest
docker push 158267493868.dkr.ecr.us-east-2.amazonaws.com/lln-intelligence:latest

# Deploy to AWS Lambda
echo "[Step 4] Updating the AWS Lambda..."
if aws lambda update-function-code \
    --function-name llnIntelligenceLambda \
    --image-uri 158267493868.dkr.ecr.us-east-2.amazonaws.com/lln-intelligence:latest \
    --profile lln-profile
then
    echo "Waiting for the deployment to complete..."
    # Polling for readiness
    success=false
    for attempt in {1..12}; do
        sleep 2
        if aws lambda update-function-configuration \
            --function-name llnIntelligenceLambda \
            --profile lln-profile \
            --timeout 120 2>&1 | grep -q "An update is in progress"; then
            echo "Attempt $attempt: Update still in progress, retrying..."
        else
            echo "Update configuration succeeded."
            success=true
            break
        fi
    done
    
    if [ "$success" = true ]; then
        echo "[Step 5] Deployment complete! Testing..."

        # Read the JSON file and encode it in base64
        PAYLOAD=$(cat tests/default.json | openssl base64)

        # Test the Lambda function
        aws lambda invoke \
        --function-name llnIntelligenceLambda \
        --payload "$PAYLOAD" response.json \
        --profile lln-profile

        # Print the contents of the response
        echo "Lambda function response:"
        cat response.json
        echo ""
    else
        echo "Failed to update function configuration after multiple attempts."
    fi
else
    echo "Failed to update the AWS Lambda function. Testing skipped."
fi
