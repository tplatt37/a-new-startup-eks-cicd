#!/bin/bash

#
# This uninstalls (DELETES!) everything.
# No snapshots, nothing is retained.
#


# Must pass in an EKS Cluster Name
if [ -z $1 ]; then
        echo "Need the EKS Cluster Name as a parameter. Exiting..."
        exit 0
fi
CLUSTER_NAME=$1

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}

PREFIX=a-new-startup-eks

# NOTE: if you invoke with --yes it will skip these "Are you sure?" prompts
if [[ $2 != "--yes" ]]; then
    read -p "This will delete all the $PREFIX-* stacks in $REGION. Are you sure? (Yy) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
    
    read -p "Are you sure you are sure???? (Yy) " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]
    then
        exit 1
    fi
fi

NAMESPACE="a-new-startup"

echo "OK... here we go..."

# Get the artifacts bucket from the Pipeline stack
EXPORT_NAME=$PREFIX-ArtifactStoreBucket
ARTIFACT_BUCKET_STORE=$(aws cloudformation list-exports --query "Exports[?Name=='$EXPORT_NAME'].Value" --output text)

# Empty the artifacts bucket (Otherwise stack delete will fail)
echo "Will empty bucket $ARTIFACT_BUCKET_STORE - to prevent stack delete from failing..."
aws s3 rm s3://$ARTIFACT_BUCKET_STORE --recursive

# Manually --force delete the ecr repo.  It will fail to delete otherwise.
EXPORT_NAME=$PREFIX-AppImage
ECR_REPO=$(aws cloudformation list-exports --query "Exports[?Name=='$EXPORT_NAME'].Value" --output text)

aws ecr delete-repository --repository-name $ECR_REPO --force

# Empty the S3 bucket used as Helm Chart Repository
EXPORT_NAME=$PREFIX-HelmChartRepo
HELM_REPO=$(aws cloudformation list-exports --query "Exports[?Name=='$EXPORT_NAME'].Value" --output text)

# Empty the chart bucket (Otherwise stack delete will fail)
echo "Will empty bucket $HELM_REPO - to prevent stack delete from failing..."
aws s3 rm s3://$HELM_REPO --recursive


# Keep this order! 

# Delete the iam service account, via eksctl -because there's a CFN Stack, and k8s objects that need to be cleaned up.
eksctl delete iamserviceaccount --cluster=$CLUSTER_NAME --name=svc-$PREFIX --namespace=$NAMESPACE
# NOTE: This doesn't cleanup the aws-auth config map entries created in 03-eks-perms.sh ... but that doesn't impact anything for our purposes.

STACK_NAME=eksctl-eks-demo-addon-iamserviceaccount-$NAMESPACE-svc-$PREFIX
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-backend
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-pipeline
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-build-projects
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

STACK_NAME=$PREFIX-repo
echo "Deleting ($STACK_NAME) ..."
aws cloudformation delete-stack --stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME 

echo "Done."