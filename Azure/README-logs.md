## JumpCloud JumpCloud App for Slack Azure Logging

The JumpCloud App for Slack in Azure makes use of [Azure Application Insights](https://azure.microsoft.com/en-us/services/monitor/#features) to track invocations for each Azure Function. Two functions drive the JumpCloud App for Slack in Azure's functionality, "HttpTrigger-ReceiveSlackCommand"
and "QueueTrigger-RunCommand". The following information can be found in each function:

HttpTrigger-ReceiveSlackCommand:
- Headers generated from the Slack POST
- The entire postBody from the Slack POST

QueueTrigger-RunCommand:
- Headers generated from the Slack POST
- The entire postBody from the Slack POST
- The PowerShell command that was executed
- The results of the PowerShell command that was executed

To Access the logs for the individual Azure Functions, First navigate to the Generated Azure Resource Group which was created during deployment to your [Azure Console](https://portal.azure.com/#home). [Resource Groups](https://portal.azure.com/#blade/HubsExtension/BrowseResourceGroups) can also be searched to find the generated resource group. Within the resource group select the corresponding Function App and select "Functions" from the left navigation column.

After selecting either "HttpTrigger-ReceiveSlackCommand" or the "QueueTrigger-RunCommand" function, select "Monitor" from the left navigation column. A detailed log of each function invocation should be available.

The last twenty invocation logs should be listed. Individual invocations and their log contents can be viewed by clicking on the timestamp. By default the invocation log will be ordered with the most recent at the top. For a detailed analysis of the function invocations, click the link to "Run Query In Application Insights" where custom filters and time ranges can be applied to your search query.

A sample query to pull all invocation HTTP data is provided below:

```
union traces | union exceptions | where timestamp > ago(30d) | where isnotempty(customDimensions['InvocationId']) | order by timestamp asc | project timestamp, message = iff(message != '', message, iff(innermostMessage != '', innermostMessage, customDimensions.['prop__{OriginalFormat}'])), logLevel = customDimensions.['LogLevel'], customDimensions['InvocationId']
```
