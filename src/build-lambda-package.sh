#!/bin/bash

ARTIFACT_BASE="$PWD/dist"
ARTIFACT_DIR="$ARTIFACT_BASE/otlp_lambda"
ARTIFACT_NAME="otlp_lambda.zip"

rm -r $ARTIFACT_DIR
mkdir -p $ARTIFACT_DIR

pushd lambda

cp main.py config.yaml -t $ARTIFACT_DIR
python -m pip install -r requirements.txt -t $ARTIFACT_DIR

popd

pushd $ARTIFACT_DIR

7z a ../$ARTIFACT_NAME *

popd