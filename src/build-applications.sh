#!/bin/bash

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
