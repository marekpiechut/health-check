# A health-check script that will nag you on Slack

It will nag you on Slack if your health checks fail.
Will also send you a a daily message with last health check timestamp,
so you know that it's doing its job.

## How to use

1. Create a Slack app and get a webhook URL
2. Paste the webhook URL into the script `SLACK_URL` value
3. Edit `health.config` and add your own checks
4. Edit `crontab.example` if you don't like my defaults
5. Run `crontab crontab.example`
6. Enjoy