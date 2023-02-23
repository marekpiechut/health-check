#!/bin/bash
#CONFIG FORMAT (one host in each line):
#APP_NAME;URL;

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
configfile="${DIR}/health.config"
reportfile="${DIR}/health.report"
logfile="${DIR}/logs/health.log"

function post_to_slack () {
  # format message as a code block ```${msg}```
  SLACK_MESSAGE="\`\`\`$1\`\`\`"
  # Slack URL with token
  SLACK_URL=https://hooks.slack.com/services/...

  case "$2" in
    INFO)
      SLACK_ICON=':ok_hand:'
      ;;
    WARNING)
      SLACK_ICON=':warning:'
      ;;
    ERROR)
      SLACK_ICON=':rotating_light:'
      ;;
    HEALTH)
      SLACK_ICON=':ambulance:'
      ;;
    FILE)
      SLACK_ICON=':file_cabinet:'
      ;;
    *)
      SLACK_ICON=':ok_hand:'
      ;;
  esac

  curl -X POST --data "payload={\"text\": \"${SLACK_ICON} ${SLACK_MESSAGE}\"}" ${SLACK_URL}
}

function run() {
  echo "Running health check: $(date)" > $reportfile
  while read -r line
  do
    line=$line
    if [ -n "$line" ]
    then
      parsed=(${line//;/ })
      app=${parsed[0]}
      url=${parsed[1]}

      timestamp=$(date +%s)
      date_str=$(date -Iseconds -u -d "@${timestamp}")
      result=$(curl -s -o /dev/null -w "%{http_code}-%{time_total}" -f -XGET $url)
      http_code=$(echo $result | cut -f1 -d-)
      http_time=$(echo $result | cut -f2 -d-)
      code="$?"
      if [ "$code" -ne "0" ]
      then
        status='FAILURE'
        post_to_slack "ERROR: Healthcheck failed for ${app} (HTTP: ${http_code}, TIME: ${http_time}, CODE ${code}): ${url}" "ERROR"
      elif [ "$http_code" -lt "200" ] || [ "$http_code" -gt "299" ]; then
        status='FAILURE'
        post_to_slack "ERROR: Healthcheck failed for ${app} (HTTP: ${http_code}, TIME: ${http_time}, CODE ${code}): ${url}" "ERROR"
      else
        status='SUCCESS'
      fi
      echo "${app} (HTTP: ${http_code}, TIME: ${http_time}, CODE ${code}): $(date -d "@${timestamp}") (${url})" >> $reportfile
      echo "${timestamp};${date_str};${status};${app};${http_code};${http_time};${code};${url}" >> $logfile
    fi
  done < $configfile
}

function report() {
  report=$(<$reportfile)
  post_to_slack "Last health check:\n${report}" "HEALTH"
}

if [ "$1" == "report" ]
then
  report
else
  run
fi
