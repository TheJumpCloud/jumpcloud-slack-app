# JumpCloud App for Slack
Manage your JumpCloud users directly from Slack using the JumpCloud App for Slack!

<p><a href="https://jumpcloud.com/blog/slack-app?wvideo=6ogzq4mfvu"><img src="https://embedwistia-a.akamaihd.net/deliveries/6d72bd3ddd07ead13a5cf2822522f277.jpg?image_play_button_size=2x&amp;image_crop_resized=960x540&amp;image_play_button=1&amp;image_play_button_color=41c8c6e0" width="400" height="225" style="width: 400px; height: 225px;"></a></p><p><a href="https://jumpcloud.com/blog/slack-app?wvideo=6ogzq4mfvu">User Administration with the JumpCloud App for Slack - JumpCloud</a></p>

## Using the JumpCloud App for Slack

The following commands can be used in your JumpCloud App for Slack.

```
/<command-name> help
```

```
/<command-name> user help
```
```User Commands Help
$($SlashCommand) user restore <username>                  # Restore a suspended JC user.
$($SlashCommand) user suspend <username>                  # Suspend a JC user.
$($SlashCommand) user unlock <username>                   # Unlock a locked JC user.
$($SlashCommand) user resetMfa <username> <days>          # Reset MFA for a JC user. Default: 7 days
$($SlashCommand) user resetPassword <username> <password> # Reset a JC user's password.
```

Either the JumpCloud Username or the Slack display name may be used for any of these commands as long as the Slack email address matches the JumpCloud email address. If this is not the case, the JumpCloud Username can still be used for any of these commands however the Slack Display Name will not complete successfully.
