# Note:
JumpCloud will no longer be supporting this Application. This archive is now read-only.

# JumpCloud App for Slack
Manage your JumpCloud users directly from Slack using the JumpCloud App for Slack! Configure this app in either [AWS](https://github.com/TheJumpCloud/jumpcloud-slack-app/tree/master/AWS) or [Azure](https://github.com/TheJumpCloud/jumpcloud-slack-app/tree/master/Azure)

<p><a href="https://jumpcloud.com/blog/slack-app?wvideo=6ogzq4mfvu"><img src="https://embedwistia-a.akamaihd.net/deliveries/6d72bd3ddd07ead13a5cf2822522f277.jpg?image_play_button_size=2x&amp;image_crop_resized=960x540&amp;image_play_button=1&amp;image_play_button_color=41c8c6e0" width="400" height="225" style="width: 400px; height: 225px;"></a></p><p><a href="https://jumpcloud.com/blog/slack-app?wvideo=6ogzq4mfvu">User Administration with the JumpCloud App for Slack - JumpCloud</a></p>

## Using the JumpCloud App for Slack

The following commands can be used in your JumpCloud App for Slack.

_Note: In order to execute these commands, the email address associated with your Slack User must also be a JumpCloud Administrator account with one of the following roles: Administrator With Billing (Super Administrator), Administrator, Manager, Help Desk._

```
/<command-name> help
```
```
/<command-name> user help
```
```User Commands Help
/<command-name> user restore <username>                  # Restore a suspended JC user.
/<command-name> user suspend <username>                  # Suspend a JC user.
/<command-name> user unlock <username>                   # Unlock a locked JC user.
/<command-name> user resetMfa <username> <days>          # Reset MFA for a JC user. Default: 7 days
/<command-name> user resetPassword <username> <password> # Reset a JC user's password.
```

Either the JumpCloud Username or the Slack display name (e.g `@Slack User`) may be used for any of these commands as long as the Slack email address matches the JumpCloud email address. If this is not the case, the JumpCloud Username can still be used for any of these commands however the Slack Display Name will not complete successfully.
