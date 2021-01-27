#Requires -Modules 'JumpCloud', 'JumpCloud.SDK.DirectoryInsights', 'JumpCloud.SDK.V1', 'JumpCloud.SDK.V2', 'AWS.Tools.Common', 'AWS.Tools.SecretsManager'

Write-Host "LambdaInput Records Body Default: $($LambdaInput.Records[0].Body)"

$body = $LambdaInput.Records[0].Body | ConvertFrom-Json
$params = $body.default | ConvertFrom-Json

#Write-Host $LambdaInput
Write-Host $params.headers
$bodySplit = $params.Body.Split('&')
$bodySplit | foreach-object {
    $KeyValue = $_.Split('=')
    Write-Host "DEBUG: Request Body: Key: '$($KeyValue[0])'; Value: '$($KeyValue[1])';"
    if ($KeyValue[0] -eq "command")
    {
        $SlashCommand = $KeyValue[1]
    }
}


$Executions.Add($LambdaContext.AwsRequestId)

$secret_manager = Get-SECSecretValue -SecretId $env:SecretsArn
$secrets = $secret_manager.SecretString | ConvertFrom-Json
$env:JCApiKey = $secrets.JcApiKey
$SigningSecret = $secrets.SlackSigningSecret
$SlackApiToken = $secrets.SlackApiToken

$postTimeStamp = $params.headers.'x-slack-request-timestamp'
$postSignature = $params.headers.'x-slack-signature'

# Format the basestring
$basestring = "v0:" + $postTimestamp + ":" + $params.originalBody


# HMAC SHA: https://gist.github.com/jokecamp/2c1a67b8f277797ecdb3
# Hex String: https://stackoverflow.com/questions/53529347/hmac-sha256-powershell-convert
$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($SigningSecret)
$signature = $hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($basestring))
$signature = [System.BitConverter]::ToString($signature).Replace('-', '').ToLower()

# Format the responce
$signature = "v0=" + $signature

# If Match, continue
If ($signature -eq $postSignature) { 
    If ($params.text) {
        $commandArray = ($params.text).Split(" ")
        if ( $commandArray[2])
        {
            if ( $commandArray[2][0] -eq "<" ) 
            {
                $SlackUserRaw = $commandArray[2]
                $regex = '\<\@([A-Z0-9]+)\|'
                $SlackUserId = [regex]::Match($SlackUserRaw, $regex).Captures.Groups[1]

                $headers = 
                @{
                    Authorization="Bearer $($SlackApiToken)"
                }

                $response = Invoke-WebRequest -Method GET -Uri "https://slack.com/api/users.info?user=$($SlackUserId)" -ContentType "application/x-www-form-urlencoded" -Headers $headers
                $response = $response.Content | ConvertFrom-Json
                $email = $response.user.profile.email

                $user = Get-JcSdkSystemUser -Filter("email:eq:$($email)")
            }
            else {
                $user = Get-JcSdkSystemUser -Filter("username:eq:$($commandArray[2])")
            }
        }
        if ( $user.id ) 
        {
            $username = $user.Username
        }
        else 
        {
            $username = $commandArray[2]
        }
        $command = switch ( $commandArray[0].ToLower() )
        {
            user
            {
                switch ( $commandArray[1].ToLower() )
                {
                    restore
                    {
                        $successMessage = "``$($username)`` has been restored.";
                        $errorMessage = "Unable to restore user ``$($username)``.";
                        "Set-JcSdkUser -id:(`'$($user.id)`') -Suspended:(`$false)"
                    }
                    suspend
                    {
                        $successMessage = "``$($username)`` has been suspended.";
                        $errorMessage = "Unable to suspend user ``$($username)``.";
                        "Set-JcSdkUser -id:(`'$($user.id)`') -Suspended:(`$true)"
                    }
                    unlock
                    {
                        $successMessage = "``$($username)`` has been unlocked.";
                        $errorMessage = "Unable to unlock user ``$($username)``.";
                        "Unlock-JcSdkUser -id:(`'$($user.id)`')"
                    }
                    resetmfa
                    {
                        $successMessage = "``$($username)``'s MFA token has been reset.";
                        $errorMessage = "Unable to reset user ``$($username)``'s MFA token.";
                        if ( $commandArray[3] )
                        {
                            $days = $commandArray[3]
                        }
                        else 
                        {
                            $days = 7
                        }
                        "Reset-JcSdkUserMfa -id(`'$($user.id)`') -Exclusion -ExclusionUntil:((Get-Date).AddDays($($days)))"
                    }
                    resetpassword
                    {
                        $successMessage = "``$($username)``'s password has been changed.";
                        $errorMessage = "Unable to reset user ``$($username)``'s password.";
                        "Set-JcSdkUser -id:(`'$($user.id)`') -Password:(`'$($commandArray[3])`')"
                    }
                    help 
                    {
                        $successMessage = "``````User Commands Help
$($SlashCommand) user restore <username>                  # Restore a suspended JC user.
$($SlashCommand) user suspend <username>                  # Suspend a JC user.
$($SlashCommand) user unlock <username>                   # Unlock a locked JC user.
$($SlashCommand) user resetMfa <username> <days>          # Reset MFA for a JC user. Default: 7 days
$($SlashCommand) user resetPassword <username> <password> # Reset a JC user's password.``````"
                        $errorMessage = "Unable to retrieve ``user help`` information."
                    }
                    default 
                    {
                        $successMessage = "Unable to parse user command. For assistance enter ``$($SlashCommand) user help``"
                        $errorMessage = "Unable to parse user command. For assistance enter ``$($SlashCommand) user help``"
                    }
                }
            }
            help
            {
                $successMessage = "For assistance with user commands enter ``$($SlashCommand) user help``."
                $errorMessage = "Unable to retrieve ``help`` information."
            }
            default 
            {
                $successMessage = "Unable to parse command. For assistance enter ``$($SlashCommand) help``"
                $errorMessage = "Unable to parse command. For assistance enter ``$($SlashCommand) help``"
            }
        }
        $ERROR.clear()
        if ($command)
        {
            $ResponseBody = Invoke-Expression -Command:($command) -ErrorVariable:('CommandError')
            Write-Host "Results of $($command): $($ResponseBody)"
        }
    }
    if ( !$ERROR ) {
        # Reply to slack with results
        Invoke-WebRequest -UseBasicParsing `
            -Body (ConvertTo-Json -Compress -InputObject @{"response_type" = "ephemeral"; "text" = "$($successMessage)" }) `
            -Method 'POST' `
            -Uri $params.response_url `
            -ContentType 'application/json'
    }
    Else {
        # Reply to slack with results
        Invoke-WebRequest -UseBasicParsing `
            -Body (ConvertTo-Json -Compress -InputObject @{"response_type" = "ephemeral"; "text" = "$($errorMessage)" }) `
            -Method 'POST' `
            -Uri $params.response_url `
            -ContentType 'application/json'
    }
}
