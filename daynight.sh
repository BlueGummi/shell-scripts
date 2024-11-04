#!/bin/bash
hour=$(date +"%H")
user=$(whoami)
if [ "$hour" -lt 12 ]; then
    greeting="good morning"
elif [ "$hour" -lt 18 ]; then
    greeting="good afternoon"
else
    greeting="good evening"
fi

echo "$greeting, $USER"
