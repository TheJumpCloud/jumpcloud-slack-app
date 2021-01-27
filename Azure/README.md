# How to Deploy the JumpCloud App for Slack in Azure

The JumpCloud App for Slack can be deployed to Azure with the click of a button, and a few additional clicks in Slack.

## Requirements

The following resources are required in both Slack and Azure to build the JumpCloud App for Slack.

Azure:

* New (or existing resource group)
* Storage account
* Application Insights
* Function App
* Key vault

App Service plan
Slack:

* New slack App
* Signing Secret
* New Slash Command

## Instructions

The following steps should be followed to deploy the JumpCloud App for Slack to your Azure and Slack tenants.

### Create the Slack App

Creating a new Slack App is relatively simple. Refer to [Slack's documentation](https://api.slack.com/apps) as necessary. Create a net new Slack App in your Slack workspace before continuing to the next step.

### Configure Azure Parameters

Click the "Deploy to Azure" button to open the deployment template in your Azure tenant.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FTheJumpCloud%2Fsupport-admin-tools%2Fmaster%2FJumpCloud.Azure%2FArmTemplates%2FdeployJCPowerShellSlackBot.json%3Ftoken%3DAM7NDWO3GZGURWVXGKJP6ZK72FD3C)

After clicking the "Deploy to Azure" button and logging in to your Azure tenant, fill out the required parameters to build the JumpCloud App for Slack in your Azure tenant.

From Slack, you'll need your App's signing secret. Copy and paste this value into Azure before building the resource

![Parameters](./images/signingSecret.png)

The JumpCloud API Key, ORG Id and slack Signing Secret parameters are all validated for correct parameter field length before the resource can be built. Optionally change the data storage retention value for extended logging (There may be additional costs associated with changing this value).

![Parameters](./images/newDeployment.png)

Click "Review + Create" and wait for the resources to complete deployment.

### Configure Slack

After the resources are built, the function url will have to be copied to your Slack App's slash command "Request URL" field to link the Slash Command to the resources in Azure.

Navigate to the newly created function app, click the functions item in the left navigation column and select the "HttpTrigger-ReceiveSlackCommand" function. Click Get Function URL and copy the url

![Parameters](./images/functionURL.png)

Paste this URL into the Slack App Slash Command "Request URL Field"

![Parameters](./images/slackAppRequestUrl.png)

### Test the App

After configuring the slack app, try to run one of the commands in your Slack Channel, your command will be processed and returned via Azure resources.
