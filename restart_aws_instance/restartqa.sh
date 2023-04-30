#!/usr/bin/env bash
set -e

[[  $# -ne 1 ]] && { echo "$(basename -- "$0"): Please pass the QA box name as argument. Ex: \"$(basename -- "$0") qa165\""; exit 1; }
[[ "${1}" =~ qa[[:digit:]]{2,3}$ ]] || { echo "\"${1}\" is not a valid QA box name"; exit 1; }

#aws sts get-caller-identity &> /dev/null || { echo "AWS CLI is not configured" ; exit 1; }

slack_webhook="https://hooks.slack.com/services/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
instance_name="${1}"
regions=("XXX" "XXX" "XXX")
domain="example.com"
script_user=$(whoami)
slack_message="User \`${script_user}\` restarted \`${instance_name}\`"

for region in "${regions[@]}"; do
  if aws ec2 describe-instances --region "${region}" --filters "Name=tag:Name,Values=${instance_name}.${domain}" "Name=tag:Service,Values=qa-box" "Name=instance-state-name,Values=running" | jq -e '.Reservations[].Instances[]' &> /dev/null; then
	  instance_id=$(aws ec2 describe-instances --region "${region}" --filters "Name=tag:Name,Values=${instance_name}.${domain}"  "Name=tag:Service,Values=qa-box" "Name=instance-state-name,Values=running" --query "Reservations[*].Instances[].InstanceId" --output text)
	  qa_owner=$(aws ec2 describe-instances --region "${region}" --instance-ids "${instance_id}" --query 'Reservations[].Instances[].Tags[?Key==`Owner`].Value' --output text)
    read -r -p "\"${instance_name}\" found in \"${region}\" region and the QA owner is \"${qa_owner}\". Do you want to proceed with restarting? [Y/N]: " response
    case "$response" in
    [yY] )
      echo "Restarting instance ${instance_name}. Wait a while before accessing"
      if aws ec2 reboot-instances --region "${region}" --instance-ids "${instance_id}"; then
        curl -s -o /dev/null -X POST -H 'Content-type: application/json; charset=utf-8' --data "{ \"channel\": \"#announce_qa_restart\", \"username\": \"qa_restart_alert_bot\", \"icon_emoji\": \":reboot_logo:\", \"text\": \"${slack_message}\" }" "${slack_webhook}"
        exit 0
      else
        echo -e "\nFailed to restart \"${instance_name}\""
        exit 1
      fi
      ;;
    [nN] )
      echo "You choose not to restart \"${instance_name}\""
      exit 0
      ;;
    *)
      echo "You choose an invalid option \"${response}\". Please chose between [yYnN]"
      exit 1
      ;;
    esac
  fi
done
echo "No running AWS QA box found with the name \"${instance_name}\""
