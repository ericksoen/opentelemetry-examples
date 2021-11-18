#!/bin/bash

ARTIFACT_BASE="$PWD/dist"
ARTIFACT_DIR="$ARTIFACT_BASE/otlp_lambda"
ARTIFACT_NAME="otlp_lambda.zip"

rm -r $ARTIFACT_DIR
mkdir -p $ARTIFACT_DIR

pushd lambda

npm install 
cp *.js config.yaml package.json -t $ARTIFACT_DIR
cp -r node_modules/ -t $ARTIFACT_DIR

popd

pushd $ARTIFACT_DIR

7z a ../$ARTIFACT_NAME *

popd