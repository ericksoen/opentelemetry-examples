#!/bin/bash

ARTIFACT_BASE="$PWD/dist"
ARTIFACT_DIR="$ARTIFACT_BASE/proxy"
ARTIFACT_NAME="lambda.zip"

rm -r $ARTIFACT_DIR
mkdir -p $ARTIFACT_DIR

pushd proxy

cp main.py -t $ARTIFACT_DIR
python -m pip install -r requirements.txt -t $ARTIFACT_DIR
popd

pushd $ARTIFACT_DIR

7z a ../$ARTIFACT_NAME *

popd