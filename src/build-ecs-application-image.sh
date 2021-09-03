#!/bin/bash

region="us-east-1"
repository=opentelemetry
tag=flask

pushd ecs

docker build . -t $repository:$tag

account_id=`aws sts get-caller-identity --query Account --output text`
ecr_url=$account_id.dkr.ecr.$region.amazonaws.com
aws ecr get-login-password --region $region | docker login --username AWS --password-stdin $ecr_url

# For now we'll assume that the repository already exists
docker tag $repository:$tag $ecr_url/$repository:$tag

docker push $ecr_url/$repository:$tag

popd