#!/bin/bash

PREFIX=a-new-startup-eks

echo "Creating simple CodePipeline pipeline (Source/Build/Deploy) ..."
aws cloudformation deploy --template-file pipeline.yaml --stack-name $PREFIX-pipeline --parameter-overrides Prefix=$PREFIX --capabilities CAPABILITY_NAMED_IAM
