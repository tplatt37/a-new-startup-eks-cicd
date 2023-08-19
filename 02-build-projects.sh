#!/bin/bash

# Must pass in an EKS Cluster Name
if [ -z $1 ]; then
        echo "Need the EKS Cluster Name as a parameter. Exiting..."
        exit 0
fi
CLUSTER_NAME=$1

# Comma delimited list of CIDRs to use for Inbound rule on SG
CIDRIPS=$2

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}
echo "Creating in $REGION...($CIDRIPS)"

PREFIX=a-new-startup-eks

# The k8s namespace to use for this app (Doesn't exist yet, but will be created by next script)
NAMESPACE="a-new-startup"

echo "Creating build projects and related roles ..."
aws cloudformation deploy --template-file build-projects.yaml --stack-name $PREFIX-build-projects \
--parameter-overrides Prefix=$PREFIX ClusterName=$CLUSTER_NAME Namespace=$NAMESPACE CIDRIPS=$CIDRIPS \
--capabilities CAPABILITY_NAMED_IAM
