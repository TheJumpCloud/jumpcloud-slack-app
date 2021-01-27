
# Get the Signature & TimeStamp from the Request Headers
$postSignature = $Request.Headers.'x-slack-signature'
$postTimestamp = $Request.Headers.'x-slack-request-timestamp'

# Format the basestring
$basestring = "v0:" + $postTimestamp + ":" + $Request.Body
# Write-Host $basestring
# Write-Host $postSignature, $postTimestamp

# Get the Signing Secret from KeyVault
$secret = $Env:SlackSecret

# HMAC SHA: https://gist.github.com/jokecamp/2c1a67b8f277797ecdb3
# Hex String: https://stackoverflow.com/questions/53529347/hmac-sha256-powershell-convert
$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($secret)
$signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($basestring))
$signature = [System.BitConverter]::ToString($signature).Replace('-', '').ToLower()

# Format the responce
$signature = "v0=" + $signature

# If Match, continue
If ($signature -eq $postSignature){
    Write-Host "PowerShell HTTP trigger function processed a request."
    If ($Request.Body) {
        # https://docs.microsoft.com/en-us/azure/azure-functions/functions-add-output-binding-storage-queue-vs-code?pivots=programming-language-powershell
        # Write the body to the queue
        Push-OutputBinding -Name msg -Value ($Request.Body)

        # Associate values to output bindings by calling 'Push-OutputBinding'.
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::OK
                ContentType = 'application/json'
                Body        = (@{"response_type" = "ephemeral"; "text" = "Message recieved!" } | ConvertTo-Json)
            })
    }
    Else {
        # Associate values to output bindings by calling 'Push-OutputBinding'.
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
                StatusCode  = [HttpStatusCode]::BadRequest
                ContentType = 'application/json'
                Body        = (@{"response_type" = "ephemeral"; "text" = "No body sent." } | ConvertTo-Json)
            })
    }
}
Else{
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
            StatusCode  = [HttpStatusCode]::BadRequest
            ContentType = 'application/json'
            Body        = (@{"response_type" = "ephemeral"; "text" = "Invalid Request." } | ConvertTo-Json)
        })
}
