#!/bin/bash
# usage: alarm <hh:mm> <alarm_file>

ALARM_TIME="$1"
ALARM_FILE="$2"
PID_FILE="/usr/local/var/run/alarm.pid"

# Save PID file
echo $$ > "$PID_FILE"

# Wait for alarm time
while [ $(date +"%H:%M") != "$ALARM_TIME" ]; do sleep 1; done

# Set sound output device to built-in
SwitchAudioSource -t output -s "Built-in Output" > /dev/null

# Set system volume to 50%
osascript -e "set Volume 1.5"

# Stop playing and exit when notification is dismissed
trap "rm $PID_FILE; kill \$(jobs -p)" EXIT

# Wake up display
caffeinate -u -t 1

# Alert notification
nohup osascript -e "tell application \"SystemUIServer\"
  display dialog \"It's $ALARM_TIME now!\" buttons \"Stop\" default button 1 with title \"Alarm\"
  do shell script \"kill \$(cat $PID_FILE)\"
  activate
end tell"  >/dev/null 2>&1 &

growlnotify -n "alarm" -N "alarm" -t "Alarm $ALARM_TIME" -m "It's $ALARM_TIME now!"

# Play alarm file until notification is dismissed
while true; do afplay "$ALARM_FILE"; done

exit
