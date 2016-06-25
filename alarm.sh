#!/bin/bash
# usage: alarm <hh:mm> <alarm_file>

ALARM_TIME="$1"
ALARM_FILE="$2"
PID=$$
PID_FILE="/usr/local/var/run/alarm_${ALARM_TIME}.pid"
echo $PID > "$PID_FILE"

# Stop playing and exit when notification is dismissed or script is stopped
trap "rm $PID_FILE; kill \$(jobs -p)" EXIT

caffeinate -i -s -w $PID &

# Wait for alarm time
while [ $(date +"%H:%M") != "$ALARM_TIME" ]; do sleep 1; done

# Set sound output device to built-in
SwitchAudioSource -t output -s "Built-in Output" > /dev/null

# Set system volume to ~50%
osascript -e "set Volume 3.5"

# Wake up
caffeinate -u -d -w $PID &

# Box notification
osascript -e "with timeout 601 seconds" \
          -e "tell application \"SystemUIServer\" to activate" \
          -e "display dialog \"It's $ALARM_TIME now!\" buttons \"Stop\" default button 1 with title \"Alarm\" giving up after 600" \
          -e "do shell script \"kill $PID\"" \
          -e "end timeout" &

# Play alarm until notification is dismissed
while true; do afplay "$ALARM_FILE"; done

exit
