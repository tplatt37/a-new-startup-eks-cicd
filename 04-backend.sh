#!/bin/bash

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}
echo "Creating in $REGION..."

PREFIX=a-new-startup-eks

echo "Creating build projects and related roles ..."
aws cloudformation deploy --template-file backend.yaml --stack-name $PREFIX-backend --parameter-overrides Prefix=$PREFIX --capabilities CAPABILITY_IAM
