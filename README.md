# Overview

Let's containerize the A-New-Startup app and get it running on an EKS cluster (via Helm) with a full CI/CD pipeline.

Given an EKS cluster, this example will create 3 CodePipeline pipelines:

1. A pipeline to build a container image of A-New-Startup
2. A pipeline to "build" (lint, really) a Helm chart to be used for installing A-New-Startup
3. A pipeline to use both the Helm chart (Stored in an S3 Chart Repo) and Container image to deploy onto the EKS Cluster.

# Requirements

You must have an EKS Cluster (see https://github.com/tplatt37/eks-cluster-creator for a great way to create a compatible EKS cluster).  
The cluster must support IRSA (IAM Roles for Service Accounts) and have the AWS Load Balancer Controller installed.

You need to supply a private S3 Bucket that will be used to temporarily house a .ZIP of source code for seeding the CodeCommit repos.

You need to have the AWS CLI, kubectl, and eksctl installed.

# Architecture

![Diagram - A-new-startup-EKS architecture](/diagrams/aws-a-new-startup-eks-arch.png)

This sample creates:

* CodeCommit Repo for the Application code, and a Helm Chart
* ECR Repo for holding the Container Image of the app
* S3 Bucket to serve as a Helm Chart Repo 
* A DynamoDB Table, SNS Topic, and SQS queue required by the app
* Three CI/CD Pipelines:
1. To build a container image of the app
2. To "build" (Lint-really) the Helm Chart - to ensure it's valid
3. And a final pipeline to deploy the latest container image to EKS, using the Helm chart.

In addition to the above, there are various IAM Roles, Policies, and Kubernetes objects created as needed.

![Diagram - A-new-startup-EKS pipelines](/diagrams/aws-a-new-startup-eks-pipelines.png)


In order to understand the application from a k8s perspective, see the Helm Chart. It consists of a Deployment, a Service, a LoadBalancer, and Ingress, Namespace, and ServiceAccount.

# Installation

I recommend setting your AWS_DEFAULT_REGION first:

```
export AWS_DEFAULT_REGION=us-east-1
```

To install, simply run this script, where BUCKET_NAME is the name of the S3 bucket you want to use, and CLUSTER_NAME is the name of an existing EKS cluster.

```
./install.sh "BUCKET_NAME" "CLUSTER_NAME"
```

# What's Next?

There are three code pipelines involved, and they all will run automatically if all is successful.

After a few minutes, you should be able to retreive the ALB DNS Name via:

```
kubectl get service -n a-new-startup
```

Open that in your web browswer, and the web app should be working.

To update the app (and trigger the CI/CD pipeline again) do the following:

Find the Clone URL (NOTE: Using ssh here) and clone easily with:
```
REPO=$(aws cloudformation list-exports --query "Exports[?Name=='a-new-startup-eks-AppRepo'].Value" --output text)
git clone $(aws codecommit get-repository --repository-name $REPO --query "repositoryMetadata.cloneUrlSsh" --output text)         
```

Modify some of the visible text in src/views/index.ejs (for an easy and visible change)

```
git commit -a -m "updated version number"

git push
```
The pipeline should then kick off with the latest commit.

In a few minutes, the app will be updated to be the latest version.

# Uninstall

First, uninstall the Helm chart:
```
helm uninstall myrelease
```

To uninstall (WARNING - This deletes EVERYTHING related to a-new-startup that was created above - no snapshots, no retain - even on the DynamoDB table)

```
./99-uninstall.sh "CLUSTER_NAME"
```

It DOES NOT delete your cluster, obviously.

NOTE: This process will leave some k8s objects still sticking around:
* secret-reader cluster role
* aws-auth configmap entries

These can be cleaned up manually.

(This repo is a DEMONSTRATION meant to be used by INSTRUCTORS - I always start with a fresh EKS Cluster.)

# A Warning

This code should NOT be considered production ready.  
While some best practices have been incorporated, the primary goal was to keep things SIMPLE so that students can absorb what they are being shown - without tons of extraneous error checking.
