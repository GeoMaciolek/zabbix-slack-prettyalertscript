#!/bin/bash

# Slack incoming web-hook URL and user name
url='CHANGEME'             # example: https://hooks.slack.com/services/QW3R7Y/D34DC0D3/BCADFGabcDEF123
username='Zabbix'

## Values received by this script:
# To = $1 (Slack channel or user to send the message to, specified in the Zabbix web interface; "@username" or "#channel")
# Subject = $2 (usually either PROBLEM {HOST.NAME} or RECOVERY {HOST.NAME}
# Message = $3 (whatever message the Zabbix action sends, preferably something like "Zabbix server is unreachable for 5 minutes - Zabbix server (127.0.0.1)")

# Get the Slack channel or user ($1), Zabbix subject (hopefully either PROBLEM or RECOVERY), and the server in question
to="$1"
subject=$(echo $2 | cut -d ':' -f 1) # The alert type is before the space, server after, eg
server=$(echo $2 | cut -d ' ' -f 5) #      "Subject: PROBLEM SomeDatabaseServer01"

# Set up the alert type (future flexibility)
if [ "$subject" == "Resolved" ]; then
        type="R"
elif [ "$subject" == "Problem" ]; then
        type="P"
else
        type="N"
fi

# Change message emoji, color, and (friendly) status depending on the subject
if [ "$type" == "R" ]; then  # Triggered by 'RECOVERY' above
        emoji=':smile:'    # A smile,
        color="#20E020"    # and red text
        status="Recovered"
elif [ "$type" == "P" ]; then  # Triggered by 'PROBLEM' above
        emoji=':frowning:'
        color="#E02020"
        status="Problem"
else
        emoji=':ghost:'
        color="#808080"
        status="N/A"
fi

# The message that we want to send to Slack is the "subject" value ($2 / $subject - that we got earlier)
#  followed by the message that Zabbix actually sent us ($3)
message="$3"

# Build our JSON payload and send it as a POST request to the Slack incoming web-hook URL
# See https://api.slack.com/docs/formatting for formatting details
payload="payload={
        \"channel\": \"${to}\",
        \"username\": \"${username}\",
        \"icon_emoji\": \"${emoji}\",
        \"attachments\": [
           {
                \"title\": \"${server}: ${status}\",
                \"fallback\": \"${message}\",
                \"text\": \"${message}\",
                \"color\": \"${color}\",
                \"mrkdwn_in\": [ \"text\" ]
           }
        ] }"

/usr/bin/curl -m 5 --data-urlencode "${payload}" $url
