#! /bin/bash

BAT=$(echo /sys/class/power_supply/BAT*)
BAT_STATUS="$BAT/status"
BAT_CAP="$BAT/capacity"
SCREEN="/sys/class/backlight/intel_backlight/brightness"

LOW_BAT_PERCENT=20

AC_PROFILE="performance"
BAT_PROFILE="balanced"
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

  if [ -z ${DY_LIGHT+x} ]; then
    echo "No DY_LIGHTm set"
  else
    echo "Set DY_LIGHT"
    BRIGHTNESS=$DY_LIGHT
  fi
  if [ -z ${DY_POWER+x} ]; then
    echo "No DY_POWER set"
  else
    echo "Set DY_POWER"
    profile=$DY_POWER
  fi

  echo "Brightness: $BRIGHTNESS"
  echo "Power profile: $profile"

  if [[ $prevB != "$BRIGHTNESS" ]]; then
    echo $SP | sudo -S sh -c "echo $BRIGHTNESS | sudo tee /sys/class/backlight/intel_backlight/brightness"
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
  date +"%T"
done
