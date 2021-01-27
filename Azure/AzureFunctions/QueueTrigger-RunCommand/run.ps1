# Input bindings are passed in via param block.
param([string] $QueueItem, $TriggerMetadata)

# Write out the queue message and insertion time to the information log.
Write-Host "PowerShell queue trigger function processed work item: $QueueItem"
Write-Host "Queue item insertion time: $($TriggerMetadata.InsertionTime)"
# Parse body
$SlackObject = [PSCustomObject]@{}
$QueueItem = [System.Web.HttpUtility]::UrlDecode($QueueItem)
$QueueItemObject = If ($QueueItem -match '&')
{
    $QueueItem.Split('&')
}
Else
{
    $QueueItem
}
$QueueItemObject | ForEach-Object {
    If ($_ -match '=')
    {
        $KevValue = $_.Split('=')
        Add-Member -InputObject:($SlackObject) -MemberType:('NoteProperty') -Name:($KevValue[0]) -Value:($KevValue[1])
        Write-Host "DEBUG: Parsing: Key: '$($KevValue[0])'; Value: '$($KevValue[1])';"
        if ($KevValue[0] -eq "command")
        {
            $SlashCommand = $KevValue[1]
        }
    }
    Else
    {
        Add-Member -InputObject:($SlackObject) -MemberType:('NoteProperty') -Name:("other") -Value:([String]$_)
    }
}

# Run PowerShell Command
If ($SlackObject.text)
{
    Write-Host "DEBUG: The user '$($SlackObject.user_name)' ran the command '$($SlackObject.text)'"
    $commandArray = ($SlackObject.text).Split(" ")
    if ($commandArray[2])
    {
        if ( $commandArray[2][0] -eq "<" )
        {
            $SlackUserRaw = $commandArray[2]
            $regex = '\<\@([A-Z0-9]+)\|'
            $SlackUserId = [regex]::Match($SlackUserRaw, $regex).Captures.Groups[1]
            $headers =
            @{
                Authorization = "Bearer $($ENV:SlackOAuthToken)"
            }
            $response = Invoke-WebRequest -Method GET -Uri "https://slack.com/api/users.info?user=$($SlackUserId)" -ContentType "application/x-www-form-urlencoded" -Headers $headers
            $response = $response.Content | ConvertFrom-Json
            $email = $response.user.profile.email
            $user = Get-JcSdkUser -Filter("email:eq:$($email)")
        }
        else
        {
            $user = Get-JcSdkUser -Filter("username:eq:$($commandArray[2])")
        }
    }
    $command = switch ( $commandArray[0].ToLower() )
    {
        user
        {
            switch ( $commandArray[1].ToLower() )
            {
                restore
                {
                    $successMessage = "``$($user.username)`` has been restored.";
                    $errorMessage = "Unable to restore ``$($user.username)``.";
                    "Set-JcSdkUser -id:(`'$($user.id)`') -Suspended:(`$false)"
                }
                suspend
                {
                    $successMessage = "``$($user.username)`` has been suspended.";
                    $errorMessage = "Unable to suspend ``$($user.username)``.";
                    "Set-JcSdkUser -id:(`'$($user.id)`') -Suspended:(`$true)"
                }
                unlock
                {
                    $successMessage = "``$($user.username)`` has been unlocked.";
                    $errorMessage = "Unable to unlock ``$($user.username)``.";
                    "Unlock-JcSdkUser -id:(`'$($user.id)`')"
                }
                resetmfa
                {
                    $successMessage = "``$($user.username)``'s MFA token has been reset.";
                    $errorMessage = "Unable to reset user ``$($user.username)``'s MFA token.";
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
                    $successMessage = "``$($user.username)``'s password has been changed.";
                    $errorMessage = "Unable to rest ``$($user.username)``'s password.";
                    "Set-JcSdkUser -id:(`'$($user.id)`') -Password:(`'$($commandArray[3])`')"
                }
                help
                {
                    $ResponseBody = $true
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
                    $ResponseBody = $true
                    $successMessage = "Unable to parse user command. For assistance enter ``$($SlashCommand) user help``"
                    $errorMessage = "Unable to parse user command. For assistance enter ``$($SlashCommand) user help``"
                }
            }
        }
        help
        {
            $ResponseBody = $true
            $successMessage = "For assistance with user commands enter ``$($SlashCommand) user help``."
            $errorMessage = "Unable to retrieve ``help`` information."
        }
        default
        {
            $ResponseBody = $true
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
if ( !$ERROR )
{
    # Reply to slack with results
    Invoke-WebRequest -UseBasicParsing `
        -Body (ConvertTo-Json -Compress -InputObject @{"response_type" = "ephemeral"; "text" = "$($successMessage)" }) `
        -Method 'POST' `
        -Uri $SlackObject.response_url `
        -ContentType 'application/json'
}
Else
{
    # Reply to slack with results
    Invoke-WebRequest -UseBasicParsing `
        -Body (ConvertTo-Json -Compress -InputObject @{"response_type" = "ephemeral"; "text" = "$($errorMessage)" }) `
        -Method 'POST' `
        -Uri $SlackObject.response_url `
        -ContentType 'application/json'
}