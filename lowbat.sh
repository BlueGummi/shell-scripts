#!/bin/bash

turn_off() {
    hyprctl keyword animations:enabled false
    hyprctl keyword decoration:blur:enabled false
    hyprctl keyword decoration:rounding 0
    hyprctl keyword decoration:drop_shadow false
    sudo cpupower frequency-set --governor powersave --max 850000
    echo "Low battery settings applied."
}

turn_on() {
    hyprctl keyword animations:enabled true
    hyprctl keyword decoration:blur:enabled true
    hyprctl keyword decoration:rounding 10
    hyprctl keyword decoration:drop_shadow true
    sudo cpupower frequency-set --governor ondemand --max 4000000
    echo "Settings restored to default."
}

if [ "$1" == "on" ]; then
    turn_off
elif [ "$1" == "off" ]; then
    turn_on
else
    echo "Usage: $0 {on|off}"
    exit 1
fi
