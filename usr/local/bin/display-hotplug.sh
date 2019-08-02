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

try_move_windows()
{
  # wait for another display to appear
  if [ $(num_displays) -eq 1 ]; then
    echo "$(date) Only 1 display found, doing nothing" >> $log_file
    return 1
  fi

  echo "$(date) Found $(num_displays) displays, moving windows" >> $log_file

  # set backlight brightness
  set_brightness $brightness

  # do the moving
  windows_to_screen_0
}

windows_to_screen_0()
{
  wmctrl -l | grep -v '\-1 ' | sort -nr -k2 | {
    while read window_def; do
      set $window_def
      window_id=$1

      if skip_window $window_def; then
        echo "$(date) Skipping window '$window_def'" >> $log_file
      else
        echo "$(date) Moving window '$window_def'" >> $log_file
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


# If 1 monitor initially, wait to find the second one and then run; else exit
# If more monitors initially, loop for a while to see if still the same number of monitors, and then run; else exit

num_tries=0
max_tries=10
pause=0.5

echo "$(date) Found $(num_displays) displays" >> $log_file

if [ $(num_displays) -eq 1 ]; then

  while ! try_move_windows && [ $num_tries -lt $max_tries ]; do
    sleep $pause
    (("num_tries++"))
  done

else

  echo "$(date) Waiting for a change..." >> $log_file

  while [ $(num_displays) -gt 1 ] && [ $num_tries -lt $max_tries ]; do
    sleep $pause
    (("num_tries++"))
  done

  if [ $(num_displays) -gt 1 ]; then
    try_move_windows
  else
    echo "$(date) Display was unplugged, exiting" >> $log_file
  fi

fi

exit 0
