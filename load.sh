loading_bar() {
    tput civis
    local total=30
    local delay
    local final_delay=2
    local rows=$(tput lines)
    local cols=$(tput cols)
    local center_row=$(( rows / 2 ))
    local center_col=$(( (cols - total) / 2 ))
    trap '' SIGINT

    cmatrix -C green -u 10 -b &

    for ((i=0; i<=total; i++)); do
        delay=$(awk -v min=0.05 -v max=0.25 'BEGIN{srand(); print min + (rand() * (max - min))}')

        hashes=$(printf "%-${i}s" "#" | tr ' ' '#')
        spaces=$(printf "%-$((total-i))s" " ")

        tput cup $center_row $center_col
        printf "[%s%s] " "$hashes" "$spaces"
        sleep $delay

        local percent=$(( (i * 100) / total ))
        local percent_message="$percent%"
        local percent_len=${#percent_message}
        local percent_col=$(( (cols - percent_len) / 2 ))

        tput cup $((center_row + 1)) $percent_col
        echo -e "\033[1;32;5m$percent_message\033[0m"
        tput cup $((center_row + 1)) $center_col
    done


    tput cup $center_row $center_col
    printf "%-$((total + 2))s" " "
    tput cup $((center_row + 1)) $percent_col
    printf "%s" " "

    kill $!
    clear
    local message="ACCESS GRANTED"
    local message_len=${#message}
    local message_col=$(( (cols - message_len) / 2 ))

    tput cup $center_row $message_col
    echo -e "\033[1;32;5m$message\033[0m"

    local percent_message="$percent%"
    local percent_len=${#percent_message}
    local percent_col=$(( (cols - percent_len) / 2 ))
    tput cup $((center_row + 1)) $percent_col
    echo -e "\033[1;32;5m$percent_message\033[0m"

    sleep $final_delay
    clear

    tput cnorm

}

loading_bar
