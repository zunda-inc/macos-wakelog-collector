#!/bin/zsh
# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

CONSOLE_USER=`ls -la /dev/console | cut -d " " -f 4`
DEVICE_SERIAL=$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}')
MANAGED_PLIST_FILE="/Library/Managed Preferences/jp.co.zunda.WakelogCollector.plist"
ENDPOINT=$(defaults read ${MANAGED_PLIST_FILE} endpoint 2>/dev/null)
TOKEN=$(defaults read ${MANAGED_PLIST_FILE} token 2>/dev/null)

function upload() {
    LOG_FILE="/var/log/wakelog_collector/$1.log"
    if [ -e $LOG_FILE ]; then
    DIGEST=$(openssl dgst -hex -sha256 ${LOG_FILE} | cut -d " " -f 2)
    TICKET_JSON=$(curl -H "Authorization: Bearer ${TOKEN}" -s "${ENDPOINT}/${DEVICE_SERIAL}/${DIGEST}?deviceSerial=${DEVICE_SERIAL}&user=${CONSOLE_USER}&logType=$1")
    read -r -d '' JXA <<EOF
        function run() {
            var data = JSON.parse(\`${TICKET_JSON}\`);
            return data.signedUrl;
        }
EOF
    UPLOAD_URL=$( osascript -l 'JavaScript' <<< "${JXA}" )
    curl -H "Content-type: text/plain" -X PUT --data-binary "@${LOG_FILE}" ${UPLOAD_URL}
    fi
}

upload display
upload power
