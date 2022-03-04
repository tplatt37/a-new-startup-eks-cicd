#!/bin/bash

# Must pass in an s3 bucket (private) where the source code zip can be stored...
if [ -z $1 ]; then
        echo "Need the S3 Bucket Name as a parameter. Exiting..."
        exit 0
fi
BUCKET=$1

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}
echo "Creating in $REGION..."

PREFIX=a-new-startup-eks

# First, we create a Zip of the latest A-New-Startup app code from Github,
# and copy it into the S3 bucket.  Cloudformation will use that to seed the CC repo.

# Make sure we don't have this folder local
rm -rf a-new-startup-github 

git clone git@github.com:tplatt37/a-new-startup.git a-new-startup-github

# NOTE: When we zip, we ignore .git folder, but include other hidden files and folders! 
cd a-new-startup-github && zip -r --exclude=*.git/* ../a-new-startup.zip ./* .[^.]* && cd ..

aws s3 cp a-new-startup.zip s3://$BUCKET

# Do the same, but for a-new-startup-eks-helm

# Make sure we don't have this folder local
rm -rf a-new-startup-eks-helm-github 

git clone git@github.com:tplatt37/a-new-startup-eks-helm.git a-new-startup-eks-helm-github

# NOTE: When we zip, we ignore .git folder, but include other hidden files and folders! 
cd a-new-startup-eks-helm-github && zip -r --exclude=*.git/* ../a-new-startup-helm.zip ./* .[^.]* && cd ..

aws s3 cp a-new-startup-helm.zip s3://$BUCKET

# Next, we need to create the CodeCommit and ECR repositories, via CloudFormation.
aws cloudformation deploy --template-file repo.yaml --parameter-overrides Prefix=$PREFIX Bucket=$BUCKET --stack-name $PREFIX-repo 


