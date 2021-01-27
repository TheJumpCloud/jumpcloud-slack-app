using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Get the Signature & TimeStamp from the Request Headers
$postSignature = $Request.Headers.'x-slack-signature'
$postTimestamp = $Request.Headers.'x-slack-request-timestamp'
# Format the basestring
$basestring = "v0:" + $postTimestamp + ":" + $Request.Body

# HMAC SHA265
$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($Env:SlackSecret)
# Format the signature
$signature = [System.BitConverter]::ToString($hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($basestring))).Replace('-', '').ToLower()
$signature = "v0=$($signature)"

# If Match, continue
If ($signature -eq $postSignature)
{
    # Write to the Azure Functions log stream.
    Write-Host "PowerShell HTTP trigger function processed a request."
    If ($Request.Body)
    {
        # https://docs.microsoft.com/en-us/azure/azure-functions/functions-add-output-binding-storage-queue-vs-code?pivots=programming-language-powershell
        # Write the body to the queue
        $bodyDecoded = [System.Web.HttpUtility]::UrlDecode($Request.Body)
        $bodySplit = $bodyDecoded.Split('&')
        $bodySplit | foreach-object {
            $KevValue = $_.Split('=')
            Write-Host "DEBUG: Request Body: Key: '$($KevValue[0])'; Value: '$($KevValue[1])';"
            if ($KevValue[0] -eq "text")
            {
                $commandText = $KevValue[1]
            }
        }
        $headers = $($Request.Headers)
        foreach ($key in $headers.Keys)
        {
            Write-Host "DEBUG: Headers: Key: $key Value: $($headers[$key])"
        }
        Push-OutputBinding -Name msg -Value ($Request.Body)

        # Associate values to output bindings by calling 'Push-OutputBinding'.
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::OK
                ContentType = 'application/json'
                Body        = (@{"response_type" = "ephemeral"; "text" = "Executing command: ``$commandText``." } | ConvertTo-Json)
            })
    }
    Else
    {
        # Associate values to output bindings by calling 'Push-OutputBinding'.
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::BadRequest
                ContentType = 'application/json'
                Body        = (@{"response_type" = "ephemeral"; "text" = "No body sent." } | ConvertTo-Json)
            })
    }
}
Else
{
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::BadRequest
            ContentType = 'application/json'
            Body        = (@{"response_type" = "ephemeral"; "text" = "Invalid Request." } | ConvertTo-Json)
        })
}