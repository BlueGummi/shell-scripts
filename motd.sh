#!/bin/bash
current_time=$(date +"%T")
timezone=$(date +"%Z")
# Define color codes
color_reset="\e[0m"          # Reset color
color_bold="\e[1m"           # Bold
color_yellow="\e[33m"        # Yellow
color_red="\e[31m"           # Red
color_blue="\e[34m"          # Blue
color_green="\e[32m"         # Green

echo -e "${color_bold}-----------------------------------------------------------${color_reset}"
echo -e "Welcome to ${color_bold}Gummi's MacBook Air!${color_reset}"
echo -e "This machine is running ${color_bold}${color_blue}Arch Linux${color_reset},"
echo -e "a ${color_bold}standalone Linux Distribution${color_reset}"
echo ""
echo -e "This machine's timezone is ${color_bold}${color_green}$timezone${color_reset}"
echo -e "The current time is ${color_bold}${color_green}$current_time${color_reset}"
echo -e "${color_bold}-----------------------------------------------------------${color_reset}"
