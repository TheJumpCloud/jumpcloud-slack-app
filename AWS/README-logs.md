## JumpCloud AWS Slackbot Logging

All logging for JumpCloud's AWS Slackbot can be found in the CloudWatch Log Streams for each Lambda function. The following information can be found in each function.

Parent Function:
- Headers generated from the Slack POST and AWS API Gateway
- The entire postBody from the Slack POST

Child Function:
- Headers generated from the Slack POST and AWS API Gateway
- The entire postBody from the Slack POST
- The PowerShell command that was executed
- The results of the PowerShell command that was executed

To Access the CloudWatch Log Streams for the Lambda functions, first navigate to the [CloudFormation page](https://console.aws.amazon.com/cloudformation) in your AWS Console. There you will find the CloudFormation stack that manages your Slackbot. The default name is `serverlessrepo-JumpCloud-Slackbot`. If you opted to change the application's name while deploying it, it will be named `serverlessrepo-Your-App-Name`.

Navigate to the "Resources" tab and locate either the `SlackbotChildFunction` or the `SlackbotParentFunction`. Click on the Physical ID. This will open the Lambda function in a new tab.

Navigate to the "Monitoring" tab and click on the "View logs in CloudWatch" button. This will open the CloudWatch Log Group in a new tab.

There will be a number of CloudWatch Log Streams under the group. The number of log streams will depend on how frequently the Slackbot is used and how much time passes between uses. 

By default the log streams will be ordered with the most recent at the top. Also by default the Search bar will search by log stream name. This can be useful if you would like to search for a specific date. If you would like to search by log contents (e.g. to find all queries executed by a specific Slack user), click the "Search All" button, which will allow you to craft a more specific search of the log contents.
