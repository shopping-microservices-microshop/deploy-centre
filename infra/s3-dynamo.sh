#!/bin/bash
set -e

REGION="us-east-1"
BUCKET_NAME="my-terraform-backend-willchrist-20250910"
DYNAMODB_TABLE="terraform-locks"

echo "🚀 Creating S3 bucket: $BUCKET_NAME in $REGION..."
aws s3api create-bucket \
  --bucket $BUCKET_NAME \
  --region $REGION

echo "🔒 Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
  --bucket $BUCKET_NAME \
  --versioning-configuration Status=Enabled

echo "🗄️ Creating DynamoDB table: $DYNAMODB_TABLE..."
aws dynamodb create-table \
  --table-name $DYNAMODB_TABLE \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region $REGION

echo "✅ S3 bucket and DynamoDB table created successfully!"
echo "   Bucket: $BUCKET_NAME"
echo "   DynamoDB Table: $DYNAMODB_TABLE"
