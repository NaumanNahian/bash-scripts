## restartqa.sh
This Bash script restarts QA box and sends alerts to Slack channel about the user who restarted QA.

## Usage
Run following command from any bastion server
```
restartqa <qaboxname>
```

## Installation script
Download the script in `/usr/local/bin` directory in any bastion server with the proper IAM role attached with permission to restart ec2. Make the script executable to all users using `chmod a+x /usr/local/bin/restartqa`. Update the AWS regions and Slack webhook token inside the script.
