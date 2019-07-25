#!/bin/bash
# Move windows to the inbuilt display for each desktop and set brightness

config_file='/usr/local/etc/display-hotplug.conf'
log_file='/var/log/display-hotplug.log'

# default settings
skip_windows=( '' )
delay=0.5
brightness=1000 # max: 1515

# override default settings
if [ -f $config_file ]; then
  . $config_file
fi

set_brightness()
{
  echo $1 > /sys/class/backlight/intel_backlight/brightness
}

num_displays()
{
  echo $(xrandr --listmonitors | head -n1 | egrep -o '[0-9]')
}

windows_to_screen_0()
{
  if [ $(num_displays) -eq 1 ]; then
    echo "$(date) Only 1 display found, doing nothing" >> $log_file
    return 1
  fi

  echo "$(date) Found $(num_displays) displays, moving windows" >> $log_file

  # do the moving
  wmctrl -l | grep -v '\-1 ' | sort -nr -k2 | {
    while read window_def; do
      if ! skip_window $window_def; then
        set $window_def
        window_id=$1
        sleep $delay
        wmctrl -i -a "$window_id"
        sleep $delay
        xte 'keydown Super_L' 'key Down' 'keyup Super_L'
      fi
    done
  }
  return 0
}

skip_window()
{
  for skip_window_name in "${skip_windows[@]}"; do
    if [[ "$1" == *"$skip_window_name"* ]]; then
      return 0
    fi
  done

  return 1
}

# set backlight brightness
# TODO: only run this if a change is detected
set_brightness $brightness

# TODO: loop for 12 seconds with a 0.5-second delay and see what kind of change it is:
# * 1->1: exit
# * 1->2: run
# * 2->2: run
# * 2->1: exit

# TODO: turn off effects before moving and then turn them back on


# TODO: problem is, when script is being triggered manually, it will exit and not do anything
#   because it is assuming there was no change
# The script should run regardless even if there was no change
# If 2 monitors initially, loop for a while to see if ext was unplugged, and then do nothing; else run
# If 1 monitor initially, wait to find the second one and then run; else exit



# initially, the number of found displays will likely be inaccurate -
# - therefore, if two displays are found, make a log entry and exit
if [ $(num_displays) -ne 1 ]; then
  echo "$(date) Found $(num_displays) displays, assuming it is too early to get an accurate reading, exiting" >> $log_file
  exit 0
fi

# try to run a few times
num_tries=0
max_tries=10

while ! windows_to_screen_0 && [ $num_tries -lt $max_tries ]; do
  sleep 1
  (("num_tries++"))
done

exit 0
