#!/bin/bash
# This script zips the contents of the ../Azure Directory & uploads to the s3Uri bucket
# Currently the 'sa-circle-ci' repository contains the JumpCloudAllForSlackAzure.zip
s3Uri='s3://sa-circle-ci'
echo "Present Working Directory:"
pwd
echo "Setting Current Working Directory to script location..."
cd "$(dirname "$0")" || exit
echo "Present Working Directory:"
pwd

# zip Azure Directory
zip -r JumpCloudAppForSlackAzure.zip ../Azure

# Upload to s3Uri
aws s3 cp ./JumpCloudAppForSlackAzure.zip $s3Uri