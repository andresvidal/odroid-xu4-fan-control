#!/bin/bash

# Loud fan control script to lower speed of fan based on current
# max temperature of any cpu
#
# See README.md for details.

#set to false to suppress logs
DEBUG=true

# Make sure only root can run our script
if (( $EUID != 0 )); then
   echo "This script must be run as root:" 1>&2
   echo "sudo $0" 1>&2
   exit 1
fi


TEMPERATURE_FILE="/sys/devices/virtual/thermal/thermal_zone0/temp"
FAN_MODE_FILE="/sys/devices/platform/pwm-fan/hwmon/hwmon0/automatic"
FAN_SPEED_FILE="/sys/devices/platform/pwm-fan/hwmon/hwmon0/pwm1"
TEST_EVERY=10 # 3 seconds (default)
new_fan_speed_default=90 # 80 (default)
LOGGER_NAME=odroid-xu4-fan-control

#make sure after quiting script fan goes to auto control
function cleanup {
  ${DEBUG} && logger -t $LOGGER_NAME "event: quit; temp: auto"
  echo 1 > ${FAN_MODE_FILE}
}
trap cleanup EXIT

function exit_xu4_only_supported {
  ${DEBUG} && logger -t $LOGGER_NAME "event: non-xu4 $1"
  exit 2
}
if [ ! -f $TEMPERATURE_FILE ]; then
  exit_xu4_only_supported "a"
elif [ ! -f $FAN_MODE_FILE ]; then
  exit_xu4_only_supported "b"
elif [ ! -f $FAN_SPEED_FILE ]; then
  exit_xu4_only_supported "c"
fi


current_max_temp=`cat ${TEMPERATURE_FILE} | cut -d: -f2 | sort -nr | head -1`
echo "fan control started. Current max temp: ${current_max_temp}"
echo "For more logs see:"
echo "sudo tail -f /var/log/syslog"

# [AV] moved outside loop to prevent mini spins
echo 0 > ${FAN_MODE_FILE} #to be sure we can manage fan

# [AV] moving outside loop to keep fan on until desired temp
new_fan_speed=2
old_fan_speed=1 # set diff than new_fan_speed so that loop calibrates


while [ true ];
do
  # [AV] move outside loop... may cause mini spins between cycles 
  # echo 0 > ${FAN_MODE_FILE} #to be sure we can manage fan

  current_max_temp=`cat ${TEMPERATURE_FILE} | cut -d: -f2 | sort -nr | head -1`
  ${DEBUG} && logger -t $LOGGER_NAME "event: read_max; temp: ${current_max_temp}"

  # [AV] moving outside loop to keep fan on until desired temp is reached
  # new_fan_speed=0
  
# [AV] Commented original
#   if (( ${current_max_temp} >= 75000 )); then
#     new_fan_speed=255
#   elif (( ${current_max_temp} >= 70000 )); then
#     new_fan_speed=200
#   elif (( ${current_max_temp} >= 68000 )); then
#     new_fan_speed=130
#   elif (( ${current_max_temp} >= 66000 )); then
#     new_fan_speed=80 
#   elif (( ${current_max_temp} >= 63000 )); then
#     new_fan_speed=80
#   elif (( ${current_max_temp} >= 60000 )); then
#     new_fan_speed=0
#   elif (( ${current_max_temp} >= 58000 )); then
#     new_fan_speed=0
#   elif (( ${current_max_temp} >= 55000 )); then
#     new_fan_speed=0
#   else
#     new_fan_speed=0
#   fi

# [AV] Updated loop 
  if (( ${current_max_temp} >= 90000 )); then
    new_fan_speed=255
  elif (( ${current_max_temp} >= 70000 )); then
    new_fan_speed=70 #255
  elif (( ${current_max_temp} >= 70000 )); then
    new_fan_speed=${new_fan_speed} #200
  elif (( ${current_max_temp} >= 68000 )); then
    new_fan_speed=${new_fan_speed} #130
  elif (( ${current_max_temp} >= 66000 )); then
    new_fan_speed=${new_fan_speed} #80
  elif (( ${current_max_temp} >= 63000 )); then
    new_fan_speed=${new_fan_speed} #80
  elif (( ${current_max_temp} >= 60000 )); then
    new_fan_speed=${new_fan_speed} #80
  elif (( ${current_max_temp} >= 58000 )); then
    new_fan_speed=${new_fan_speed} #80
  elif (( ${current_max_temp} >= 55000 )); then
    new_fan_speed=2
  else
    new_fan_speed=2
  fi

  
  
# [AV] Commented original 
#   ${DEBUG} && logger -t $LOGGER_NAME "event: adjust; speed: ${new_fan_speed}"
#   echo ${new_fan_speed} > ${FAN_SPEED_FILE}

# [AV] only update FAN_SPEED_FILE when values are changed. minimize logging
  if (( ${old_fan_speed} != ${new_fan_speed} )); then
    ${DEBUG} && logger -t $LOGGER_NAME "event: adjust; speed: ${new_fan_speed}"
    echo ${new_fan_speed} > ${FAN_SPEED_FILE}
    old_fan_speed=${new_fan_speed}
  fi

  sleep ${TEST_EVERY}
done
