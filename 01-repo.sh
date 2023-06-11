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

echo "Attemping to retrieve latest a-new-startup app source code from git@github.com:tplatt37/a-new-startup.git using ssh..."
git clone git@github.com:tplatt37/a-new-startup.git a-new-startup-github
if [ $? -eq 128 ]; then
        echo "But... that failed, so we'll use a possibly out of date zip instead."
        cp a-new-startup-fallback.zip a-new-startup.zip
else
        # If it was successful, zip up what was cloned
        # NOTE: When we zip, we ignore .git folder, but include other hidden files and folders! 
        echo "Success! Let's zip it up!"
        cd a-new-startup-github && zip -r --exclude=*.git/* ../a-new-startup.zip ./* .[^.]* && cd ..
        # Save this for next time, in case we can't get the code live.
        # (This makes the maintainer's life easier)
        cp a-new-startup.zip a-new-startup-fallback.zip 
fi

aws s3 cp a-new-startup.zip s3://$BUCKET

# Do the same, but for a-new-startup-eks-helm

# Make sure we don't have this folder local
rm -rf a-new-startup-eks-helm-github 


echo "Attemping to retrieve latest a-new-startup helm chart source code from git@github.com:tplatt37/a-new-startup-eks-helm.git using ssh..."
git clone git@github.com:tplatt37/a-new-startup-eks-helm.git a-new-startup-eks-helm-github
if [ $? -eq 128 ]; then
        echo "But... that failed, so we'll use a possibly out of date zip instead."
        cp a-new-startup-helm-fallback.zip a-new-startup-helm.zip
else
        # If it was successful, zip up what was cloned
        # NOTE: When we zip, we ignore .git folder, but include other hidden files and folders! 
        echo "Success! Let's zip it up!"
        cd a-new-startup-eks-helm-github && zip -r --exclude=*.git/* ../a-new-startup-helm.zip ./* .[^.]* && cd ..
        # Save this for next time, in case we can't get the code live.
        # (This makes the maintainer's life easier)
        cp a-new-startup-helm.zip a-new-startup-helm-fallback.zip 
fi

# This zip file must be there so that CodeCommit can use it to populate the repo
aws s3 cp a-new-startup-helm.zip s3://$BUCKET

# Next, we need to create the CodeCommit and ECR repositories, via CloudFormation.
aws cloudformation deploy \
  --template-file repo.yaml \
  --parameter-overrides Prefix=$PREFIX Bucket=$BUCKET \
  --stack-name $PREFIX-repo 
