#! /bin/bash

BAT=$(echo /sys/class/power_supply/BAT*)
BAT_STATUS="$BAT/status"
BAT_CAP="$BAT/capacity"
SCREEN="/sys/class/backlight/intel_backlight/brightness"

LOW_BAT_PERCENT=20

AC_PROFILE="performance"
BAT_PROFILE="power-saver"
LOW_BAT_PROFILE="power-saver"

HIGH_SCREEN=16961
LOW_SCREEN=8000
SAVER_SCREEN=500

SP="Sys49152"

# wait a while if needed
[[ -z $STARTUP_WAIT ]] || sleep "$STARTUP_WAIT"

# start the monitor loop
prev=0
prevB=0
BRIGHTNESS=$LOW_SCREEN

while true; do
  # read the current state
  if [[ $(cat "$BAT_STATUS") == "Discharging" ]]; then
    if [[ $(cat "$BAT_CAP") -gt $LOW_BAT_PERCENT ]]; then
      profile=$BAT_PROFILE
      BRIGHTNESS=$LOW_SCREEN
      # echo $LOW_SCREEN | sudo tee /sys/class/backlight/amdgpu_bl0/brightness
    else
      profile=$LOW_BAT_PROFILE
      BRIGHTNESS=$SAVER_SCREEN
    fi
  else
    profile=$AC_PROFILE
    BRIGHTNESS=$HIGH_SCREEN
  fi
  echo "Brightness > $BRIGHTNESS"
  if [[ -z "${DY_LIGHT+x}" ]]; then
    echo "nope"
  else
    echo "settt ---"
    BRIGHTNESS=$DY_LIGHT
  fi
  if [ -z "${DY_POWER+x}" ]; then
    BRIGHTNESS=$DY_POWER
  fi
  echo "Bat status $BAT_STATUS > $(cat "$BAT_STATUS")"
  echo "Brightness $BRIGHTNESS"
  if [[ $prevB != "$BRIGHTNESS" ]]; then
    echo $SP | sudo -S sh -c "echo $BRIGHTNESS | sudo tee $SCREEN"
  fi

  # set the new profile
  if [[ $prev != "$profile" ]]; then
    # echo setting power profile to $profile
    powerprofilesctl set $profile
  fi
  prev=$profile
  prevB=$BRIGHTNESS
  # wait for the next power change event
  inotifywait -qq "$BAT_STATUS" "$BAT_CAP"
done
