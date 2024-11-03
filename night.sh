#!/bin/bash

update_temperature() {
    local change=$1
    busctl --user -- call rs.wl-gammarelay / rs.wl.gammarelay UpdateTemperature n "$change"
}

echo "Press the Up arrow to increase temperature by 500 or Down arrow to decrease by 500."
echo "Press 'q' to quit."

while true; do
    read -rsn1 input

    if [[ $input == $'\e' ]]; then
        read -rsn2 input
        case $input in
            '[A')
                update_temperature 500
                ;;
            '[B')
                update_temperature -500
                ;;
        esac
    elif [[ $input == 'q' ]]; then
        echo "Quitting."
        break
    fi
done
