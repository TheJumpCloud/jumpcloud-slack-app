# JumpCloud Slackbot
_This document will walk a JumpCloud Administrator through packaging and deploying this Serverless Application manually. This workflow is intended for those who need to make modifications to the code or tie this solution into other AWS resources. If you would simply like to deploy this Serverless Application as-is, you can do so from the Serverless Application Repository \<placeholder for link when it is offically published\>_


## Table of Contents
- [JumpCloud Slackbot](#jumpcloud-slackbot)
  - [Table of Contents](#table-of-contents)
  - [Pre-requisites](#pre-requisites)
  - [Create a Slack Application](#create-a-slack-application)
  - [Create PowerShell Scripts](#create-powershell-scripts)
  - [Create SAM Template](#create-sam-template)
  - [Package and Deploy the Application](#package-and-deploy-the-application)
    - [Packaging the Application](#packaging-the-application)
    - [Deploying the Application](#deploying-the-application)
    - [Alternative: Publish the Application](#alternative-publish-the-application)
  - [Create a Slash Command](#create-a-slash-command)

## Pre-requisites
- [Your JumpCloud API key](https://docs.jumpcloud.com/2.0/authentication-and-authorization/authentication-and-authorization-overview)
- [JumpCloud PowerShell Module installed](https://support.jumpcloud.com/support/s/article/installing-the-jumpcloud-powershell-module-2019-08-21-10-36-47)
- [AWS SAM CLI installed](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)
- [AWSPowerShell.NetCore installed](https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up-windows.html)
- [AWS CLI installed](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) (Only required for deploying from the CLI, not if privately publishing)
- A valid Amazon S3 bucket policy that grants the service read permissions for artifacts uploaded to Amazon S3 when you package your application.
  - Go to the [S3 Console](https://s3.console.aws.amazon.com/s3/)
  - Choose the S3 bucket that you will use to package your application
  - Permissions > Bucket Policy
  - Paste the following Policy Statement into the Bucket Policy Editor (replace `<YOUR BUCKET NAME>` with the name of your S3 bucket)
    ```
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Principal": {
                    "Service":  "serverlessrepo.amazonaws.com"
            },
           "Action": "s3:GetObject",
           "Resource": "arn:aws:s3:::<YOUR BUCKET NAME>/*"
        }
        ]
    }
    ```
  
## Create a Slack Application

In a browser, navigate to [your Slack apps](https://api.slack.com/apps) and click the "Create New App" button. Provide your Slack app with a name and select which Workplace you would like it to be used in. Take note of the [Signing Secret](https://api.slack.com/authentication/verifying-requests-from-slack#about); this will used during the deployment of the Serverless Application.

## Create PowerShell Scripts

Create a directory to store your Serverless Application and any dependencies required. Copy both the [slack-parent.ps1](https://github.com/TheJumpCloud/support-admin-tools/blob/master/Kyles%20Stuff/AWS%20SAM/powershell/slackbot/slack-parent.ps1) and [slack-child.ps1](https://github.com/TheJumpCloud/support-admin-tools/blob/master/Kyles%20Stuff/AWS%20SAM/powershell/slackbot/slack-child.ps1) files into the root of this directory.

Create a ZIP archive for each of the PowerShell scripts and their dependencies.
```
/jc-slackbot> New-AWSPowerShellLambdaPackage -ScriptPath ./slack-parent.ps1 -OutputPackage slack-parent.zip
/jc-slackbot> New-AWSPowerShellLambdaPackage -ScriptPath ./slack-child.ps1 -OutputPackage slack-child.zip
```

_Note: Please take note of the output of these commands. If any changes were made to the names used above, you will need to update the `Handler` in your SAM template below to match the ouput of these commands._

## Create SAM Template

In the root of your directory, copy the SAM template named [template.yaml](https://github.com/TheJumpCloud/support-admin-tools/blob/master/Kyles%20Stuff/AWS%20SAM/powershell/slackbot/template.yaml).

_Note: The example template provided assumes that you have named the ZIP files for your Parent and Child functions slack-parent.zip and slack-child.zip. If this is not true, update the `CodeUri` property to reflect the correct names._ \
_This also assumes the name of your PowerShell scripts are slack-parent.ps1 and slack-child.ps1. If either of these assumptions is not true, update the `Handler` for each function to match the output of the commands that created the ZIP archives earlier in these instructions._

## Package and Deploy the Application

### Packaging the Application
Using the AWS SAM CLI, package your application. This will upload your ZIP archives and `template.yaml` file to an S3 bucket. It will also create a file named `packaged.yaml` in your directory. `packaged.yaml` is an updated version of the SAM template that you provided that now directs to your S3 bucket and the script and dependencies now stored within it.
```
/jc-slackbot> sam package --template-file template.yaml --output-template-file packaged.yaml --s3-bucket <YOUR S3 BUCKET>
```
_Note: Provide the name of the S3 bucket that you created for packaging and storing your application._


### Deploying the Application

Using the AWS CLI, you can [deploy](https://docs.aws.amazon.com/cli/latest/reference/cloudformation/deploy/index.html) your template directly from your terminal.
```
/jc-slackbot> aws cloudformation deploy --template-file ./packaged.yaml --stack-name <YOUR STACK NAME> --parameter-overrides JumpCloudApiKey=<API KEY> OrganizationId=<ORGANIZATION ID> SlackSigningString=<SLACK SIGNING STRING>
```

### Alternative: Publish the Application

Rather than deploying your Application from the CLI, you can also publish your application so that it is viewable via the [Severless Application Repository](https://console.aws.amazon.com/serverlessrepo/). By default, published applications are "Private" so they will not be publicly available until set otherwise.

Using the AWS SAM CLI, publish your application to the Serverless Applications Repository.
```
/jc-slackbot> sam publish --template packaged.yaml --region <REGION>
```
Once you have published your Application to the [Severless Application Repository](https://console.aws.amazon.com/serverlessrepo/), you can find and deploy your application from the Private Applications tab.

### Create a Slack Slash Command

Once your Serverless Application has been deployed, return to your [Slack Apps](https://api.slack.com/apps) and select the Slack App that you created for this project. Under "Add Features and Functionality", click "Slash Commands". Click the "Create New Command". Enter the name of the command you would like to use (e.g. `/jumpcloud`).

To get the request URL, go to the [CloudFormation stack](https://console.aws.amazon.com/cloudformation/) that was created when you deployed your Serverless application. From the "Resources" tab, click on the Physical ID of the "SlackbotAPI". Click on "Stages" in the navigation menu on the left and expand the "live" stage. Click on "POST" and copy the "Invoke URL". Paste the "Invoke URL" into the "Request URL" box in the Slack application. Click Save.
