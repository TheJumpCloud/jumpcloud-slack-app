#Requires -Modules 'AWS.Tools.Common', 'AWS.Tools.SQS'

$headers = $LambdaInput.headers
Write-Host "JumpCloud Slackbot HTTP Parent Headers: $($headers)"
Write-Host "Uneditted body: `r`n" +$Body
$Body = [System.Web.HttpUtility]::UrlDecode($LambdaInput.postBody)
$SlackObject = [PSCustomObject]@{}
$BodyObject = If ($Body -match '&')
{
    $Body.Split('&')
}
Else
{
    $Body
}
$BodyObject | ForEach-Object {
    If ($_ -match '=')
    {
        $KevValue = $_.Split('=')
        Add-Member -InputObject:($SlackObject) -MemberType:('NoteProperty') -Name:($KevValue[0]) -Value:($KevValue[1])
        Write-Host "DEBUG: Parsing: Key: '$($KevValue[0])'; Value: '$($KevValue[1])';"
    }
    Else
    {
        Add-Member -InputObject:($SlackObject) -MemberType:('NoteProperty') -Name:("other") -Value:([String]$_)
    }
}

$content = @{
        Body = $Body;
        originalBody = $LambdaInput.postBody;
        response_url = $SlackObject.response_url;
        text = $SlackObject.text;
        headers = $headers;
} | ConvertTo-Json

$message = @{
    default = $content;
} | ConvertTo-Json

Send-SQSMessage -QueueUrl $env:SQSQueueUrl -MessageBody $message

$Back2Slack = "Executing command ``$($SlackObject.text)``."
$Back2Slack
