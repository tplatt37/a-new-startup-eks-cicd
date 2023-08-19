#!/bin/bash

# Must pass in an s3 bucket (private) where the source code zip can be stored...
if [ -z $1 ]; then
        echo "Need the S3 Bucket Name as a parameter. Exiting..."
        exit 0
fi
BUCKET=$1

# Must pass in an EKS Cluster Name
if [ -z $2 ]; then
        echo "Need the EKS Cluster Name as a parameter. Exiting..."
        exit 0
fi
CLUSTER_NAME=$2

# Optional 3rd parameter is a comma delimited list of CIDR IPs
CIDRIPS=$3

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}
echo "Creating in $REGION... using bucket $BUCKET. ELB access will be limited to $CIDRIPS..."

# Confirm cluster is valid
aws eks describe-cluster --name $CLUSTER_NAME > /dev/null 
if [ $? -ne 0 ]; then
        echo "Cluster named $CLUSTER_NAME in region $REGION doesn't seem to exist..."
        exit 254
fi

echo "Creating repos..."
./01-repo.sh $BUCKET

echo "Creating build-projects..."
./02-build-projects.sh $CLUSTER_NAME $CIDRIPS

echo "Creating EKS permissions..."
./03-eks-perms.sh $CLUSTER_NAME

echo "Creating pipeline..."
./04-pipeline.sh

echo "Done."