#!/bin/bash
# This script zips the contents of the ../Azure Directory & uploads to the s3Uri bucket
# Currently the 'sa-circle-ci' repository contains the JumpCloudAllForSlackAzure.zip
s3Uri='s3://jcautopkg'
echo "Present Working Directory:"
pwd
echo "Setting Current Working Directory to script location..."
cd "$(dirname "$0")" || exit
echo "Present Working Directory:"
pwd

# make directory
mkdir JumpCloudAppForSlackAzure

# copy files/ directories into newly created location
cp -R ../Azure/AzureFunctions/HttpTrigger-RecieveSlackCommand ./JumpCloudAppForSlackAzure
cp -R ../Azure/AzureFunctions/QueueTrigger-RunCommand ./JumpCloudAppForSlackAzure
cp ../Azure/AzureFunctions/host.json ./JumpCloudAppForSlackAzure
cp ../Azure/AzureFunctions/profile.ps1 ./JumpCloudAppForSlackAzure
cp ../Azure/AzureFunctions/proxies.json ./JumpCloudAppForSlackAzure
cp ../Azure/AzureFunctions/requirements.psd1 ./JumpCloudAppForSlackAzure


# zip Azure Directory | zip w/ deflate compression for all os compatibility
zip -r -Z deflate JumpCloudAppForSlackAzure.zip ./JumpCloudAppForSlackAzure

# Upload to s3Uri
aws s3 cp ./JumpCloudAppForSlackAzure.zip $s3Uri