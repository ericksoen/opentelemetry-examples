#!/bin/bash

region="us-east-1"
repository=opentelemetry
tag=agent

pushd ecs-agent-sidecar
docker build . -t $repository:$tag

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to build $repository:$tag successfully. Exiting..."
    exit 1
fi

account_id=`aws sts get-caller-identity --query Account --output text`
ecr_url=$account_id.dkr.ecr.$region.amazonaws.com
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $ecr_url

# For now we'll assume that the repository already exists
docker tag $repository:$tag $ecr_url/$repository:$tag

docker push $ecr_url/$repository:$tag

if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to push to $ecr_url. Exiting..."
    exit 1
fi 