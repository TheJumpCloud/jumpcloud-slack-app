#!/bin/bash
# This script zips the contents of the ../Azure Directory
# Currently the 'sa-circle-ci' repository contains the JumpCloudAllForSlackAzure.zip
s3Uri='s3://sa-circle-ci'

zip -r JumpCloudAppForSlackAzure.zip ../Azure

aws s3 cp ./JumpCloudAppForSlackAzure.zip $s3Uri