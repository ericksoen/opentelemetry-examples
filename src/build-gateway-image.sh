#!/bin/bash

region="us-east-1"
repository=opentelemetry
tag=dev

docker build . -t $repository:$tag

if [ $? -ne 0 ]; then
    echo "[ERROR] Did not build docker image $repository:$tag successfully. Exiting..."
    exit 1
fi

account_id=`aws sts get-caller-identity --query Account --output text`
ecr_url=$account_id.dkr.ecr.$region.amazonaws.com
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $ecr_url

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to retrieve ECR loging password. Exiting..."
    exit 1
fi

# For now we'll assume that the repository already exists
docker tag $repository:$tag $ecr_url/$repository:$tag

docker push $ecr_url/$repository:$tag

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to push image to $ecr_url. Exiting..."
    exit 1
fi

if [ $? -ne 0 ]; then
  echo "[ERROR] Failed to correctly build and push docker image Exiting..."
  exit 1
fi
