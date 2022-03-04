#!/bin/bash

# Must pass in an EKS Cluster Name
if [ -z $1 ]; then
        echo "Need the EKS Cluster Name as a parameter. Exiting..."
        exit 0
fi
CLUSTER_NAME=$1

REGION=${AWS_DEFAULT_REGION:-$(aws configure get default.region)}

# Make sure our Kubectl is pointed to the new cluster (it should be)
aws eks update-kubeconfig --name $CLUSTER_NAME

PREFIX=a-new-startup-eks

# We have to setup the perms that CodeBuild is going to need to be able to deploy to the cluster.

# Create the mynamespace. 
NAMESPACE=a-new-startup
kubectl create ns $NAMESPACE

# Helm uses Secrets to store config information.  The subject we use will need this cluster role.
kubectl apply -f cluster-role-secret-reader.yaml 

# Setting a RoleBinding in multiple namespaces.
kubectl create rolebinding codebuild-deploy-admin --clusterrole=admin --user=codebuild-deploy -n $NAMESPACE
kubectl create rolebinding codebuild-deploy-admin-default --clusterrole=admin --user=codebuild-deploy -n default 

# Giving ability to read secrets cluster wide, also needed by Helm.
kubectl create clusterrolebinding codebuild-secret-reader --clusterrole=secret-reader --user=codebuild-deploy

# Need to get the Arn of the Role that the Build Project uses in CodeBuild. It's an Export in one of the stacks.
EXPORT_NAME=$PREFIX-BuildRole
DEPLOY_ROLE_ARN=$(aws cloudformation list-exports --query "Exports[?Name=='$EXPORT_NAME'].Value" --output text)
echo "Build Role Arn is $DEPLOY_ROLE_ARN"

# This maps the k8s permissions to this role.  The IAM role above will be recognized as "codebuild-deploy" in k8s RBAC
eksctl create iamidentitymapping --cluster $CLUSTER_NAME --arn $DEPLOY_ROLE_ARN --username codebuild-deploy

# Show aws-auth configmap as a simple verification that updates worked.
kubectl describe configmap/aws-auth -n kube-system