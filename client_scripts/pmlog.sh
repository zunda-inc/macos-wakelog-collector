#!/bin/zsh
# Copyright 2022 ZUNDA Inc.
# 
# Use of this source code is governed by an MIT-style
# license that can be found in the LICENSE file or at
# https://opensource.org/licenses/MIT.

LOG_DIR="/var/log/wakelog_collector"
DISPLAY_LOG_FILE="${LOG_DIR}/display.log"
POWER_LOG_FILE="${LOG_DIR}/power.log"
MANAGED_CONFIG_NAMESPACE="jp.co.zunda.WakelogCollector"
MAX_LINES=200

mkdir -p $LOG_DIR

(
    cat $DISPLAY_LOG_FILE 2>/dev/null;
    pmset -g log | grep -e "\tKernel Idle sleep preventers" -e "\tDisplay is turned"
) \
  | sort | uniq | tail -n${MAX_LINES} \
> $DISPLAY_LOG_FILE

last shutdown | grep -E "^shutdown" | sed -e "s/shutdown.*\(.\{17\}\)/\1/g" \
  | while read line; 
    do echo "$(LANG=C date -j -f '%a %b %d %H:%M' '+%Y-%m-%d %H:%M:00 %z' $line)\tshutdown"; 
    done \
>> $POWER_LOG_FILE 

last reboot | grep -E "^reboot" | sed -e "s/reboot.*\(.\{17\}\)/\1/g" \
  | while read line; 
    do echo "$(LANG=C date -j -f '%a %b %d %H:%M' '+%Y-%m-%d %H:%M:00 %z' $line)\treboot"; 
    done \
>> $POWER_LOG_FILE

pmset -g log | grep -E "\b(Start)\s{2,}" | sed -e "s/^\(.\{25\}\).*/\1/g" \
  | while read line; 
    do echo "${line}\tstart"; 
    done \
>> $POWER_LOG_FILE

cat $POWER_LOG_FILE | sort | uniq | tail -n${MAX_LINES} | tee $POWER_LOG_FILE >/dev/null
