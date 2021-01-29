#Requires -Modules 'JumpCloud', 'JumpCloud.SDK.DirectoryInsights', 'JumpCloud.SDK.V1', 'JumpCloud.SDK.V2', 'AWS.Tools.Common', 'AWS.Tools.SecretsManager'
 
$body = $LambdaInput.Records[0].Body | ConvertFrom-Json
$params = $body.default | ConvertFrom-Json

Write-Host $params.headers
$bodySplit = $params.Body.Split('&')
$bodySplit | foreach-object {
    $KeyValue = $_.Split('=')
    Write-Host "DEBUG: Request Body: Key: '$($KeyValue[0])'; Value: '$($KeyValue[1])';"
    if ($KeyValue[0] -eq "command")
    {
        $SlashCommand = $KeyValue[1]
    }
    elseif ( $KeyValue[0] -eq "user_id" )
    {
        $SlackAdminId = $KeyValue[1]
    }
}

$secret_manager = Get-SECSecretValue -SecretId $env:SecretsArn
$secrets = $secret_manager.SecretString | ConvertFrom-Json
$env:JCApiKey = $secrets.JcApiKey
$SigningSecret = $secrets.SlackSigningString
$SlackApiToken = $secrets.SlackApiToken
$AllowedRoles = @(
    "Administrator With Billing",
    "Administrator",
    "Manager",
    "Help Desk"
)

$postTimeStamp = $params.headers.'x-slack-request-timestamp'
$postSignature = $params.headers.'x-slack-signature'

# Format the basestring
$basestring = "v0:" + $postTimestamp + ":" + $params.originalBody

# HMAC SHA265
$hmacsha = New-Object System.Security.Cryptography.HMACSHA256
$hmacsha.key = [Text.Encoding]::ASCII.GetBytes($SigningSecret)
# Format the signature
$signature = [System.BitConverter]::ToString($hmacsha.ComputeHash([Text.Encoding]::ASCII.GetBytes($basestring))).Replace('-', '').ToLower()
$signature = "v0=$($signature)"

#Check if the person executing the Slack command is a JumpCloud Admin
$JumpCloudAdminUri = "https://console.jumpcloud.com/api/users"
$JumpCloudAdminHeaders = @{
    'x-api-key' = $env:JCApiKey
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
}
$JumpCloudAdmins = (Invoke-RestMethod -Uri $JumpCloudAdminUri -Method GET -Headers $JumpCloudAdminHeaders).results

$SlackHeaders = @{
    Authorization="Bearer $($SlackApiToken)"
}

$SlackAdmin = Invoke-WebRequest -Method GET -Uri "https://slack.com/api/users.info?user=$($SlackAdminId)" -ContentType "application/x-www-form-urlencoded" -Headers $SlackHeaders
$SlackAdmin = $SlackAdmin.Content | ConvertFrom-Json
$SlackAdminEmail = $SlackAdmin.user.profile.email

if ( $SlackAdminEmail -in $JumpCloudAdmins.email )
{
    $JumpCloudAdminRole = ($JumpCloudAdmins | Where-Object { $_.email -eq $SlackAdminEmail }).roleName
    if ( $JumpCloudAdminRole -in $AllowedRoles )
    {
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

                        $response = Invoke-WebRequest -Method GET -Uri "https://slack.com/api/users.info?user=$($SlackUserId)" -ContentType "application/x-www-form-urlencoded" -Headers $SlackHeaders
                        $response = $response.Content | ConvertFrom-Json
                        $email = $response.user.profile.email

                        $user = Get-JcSdkUser -Filter("email:eq:$($email)")
                    }
                    else {
                        $user = Get-JcSdkUser -Filter("username:eq:$($commandArray[2])")
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
    }
    else {
    $PermissionsMessage = "Unable to complete this command. Your JumpCloud Administrator account does not have sufficient permissions to execute this command."
     # Reply to slack with results
        Invoke-WebRequest -UseBasicParsing `
            -Body (ConvertTo-Json -Compress -InputObject @{"response_type" = "ephemeral"; "text" = "$($PermissionsMessage)" }) `
            -Method 'POST' `
            -Uri $params.response_url `
            -ContentType 'application/json'
}
}
else {
    $PermissionsMessage = "Unable to complete this command. Your account is not associated with a JumpCloud Administrator account."
     # Reply to slack with results
        Invoke-WebRequest -UseBasicParsing `
            -Body (ConvertTo-Json -Compress -InputObject @{"response_type" = "ephemeral"; "text" = "$($PermissionsMessage)" }) `
            -Method 'POST' `
            -Uri $params.response_url `
            -ContentType 'application/json'
}
