#!/bin/bash

./build-ecs-agent-sidecar-image.sh

if [ $? -ne 0 ]; then
    echo "[ERROR] Did not build agent sidecar successfully"
    exit 1
fi

./build-ecs-application-image.sh

if [ $? -ne 0 ]; then
    echo "[ERROR] Did not build ECS application service successfully"
    exit 1
fi

./build-lambda-package.sh

if [ $? -ne 0 ]; then
    echo "[ERROR] Did not build Lambda package"
    exit 1
fi

./build-lambda-package.sh

if [ $? -ne 0 ]; then
    echo "[ERROR] Did not build Lambda package"
    exit 1
fi
