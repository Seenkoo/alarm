#!/bin/bash
# usage: alarm <hh:mm> <alarm_file>

function set_alarm_time() {
  case "$1" in
  [01][0-9]:[0-5][0-9]|2[0-3]:[0-5][0-9]) ALARM_TIME="$1";;
  (*) (>&2 echo "Invalid time format. Correct format is <hh:mm>.")
    exit 1;;
  esac
}

set_alarm_time "$1"

ALARM_FILE=$(realpath -- "$2")

function write_pid() {
  # PID Directory
  PID_DIR="/usr/local/var/run/alarm"
  mkdir -p -- "$PID_DIR" &>/dev/null
  if [ ! -d "$PID_DIR" ] || [ ! -w "$PID_DIR" ] || [ -L "$PID_DIR" ]; then
    (>&2 echo "Can't use directory ${PID_DIR}.")
    exit 126
  fi

  # PID File
  PID=$$
  PID_FILE="${PID_DIR}/${ALARM_TIME}.pid"
  if [ -f "$PID_FILE" ]; then
    (>&2 echo "LOCK: PID file ${PID_FILE} already exists.")
    exit 126
  fi
  echo "$PID" > "$PID_FILE"
}

write_pid

# Stop playing and exit when notification is dismissed or script is stopped
trap "rm -- ${PID_FILE}; kill \$(jobs -p)" EXIT

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
