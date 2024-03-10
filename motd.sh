# put this file in /etc/profile.d/motd.sh
# add 
# session    optional     pam_motd.so /etc/profile.d/motd.sh
# to /etc/pam.d/login
#!/bin/bash
current_time=$(date +"%T")
timezone=$(date +"%Z")
hostname=$(cat /etc/hostname)
kernel_version=$(uname -r)
architecture=$(uname -m)
# Define color codes
color_reset="\e[0m"          # Reset color
color_bold="\e[1m"           # Bold
color_yellow="\e[33m"        # Yellow
color_red="\e[31m"           # Red
color_blue="\e[34m"          # Blue
color_green="\e[32m"         # Green
logo=$(cat << "EOF" 
 __          __  ______   _         _____    ____    __  __   ______   _ 
 \ \        / / |  ____| | |       / ____|  / __ \  |  \/  | |  ____| | |
  \ \  /\  / /  | |__    | |      | |      | |  | | | \  / | | |__    | |
   \ \/  \/ /   |  __|   | |      | |      | |  | | | |\/| | |  __|   | |
    \  /\  /    | |____  | |____  | |____  | |__| | | |  | | | |____  |_|
     \/  \/     |______| |______|  \_____|  \____/  |_|  |_| |______| (_)
EOF
)

# Print the welcome message with the logo
echo -e "${color_bold}$logo${color_reset}" | lolcat

echo -e "${color_bold}-----------------------------------------------------------------------${color_reset}"
echo -e "Welcome to ${color_bold}Gummi's MacBook Air!${color_reset}"
echo -e "This machine is running ${color_bold}${color_blue}Arch Linux${color_reset},"
echo -e "a ${color_bold}standalone Linux Distribution${color_reset}"
echo ""
echo -e "Hostname: ${color_bold}${color_green}$hostname${color_reset}"
echo -e "Kernel Version: ${color_bold}${color_green}$kernel_version${color_reset}"
echo -e "Architecture: ${color_bold}${color_green}$architecture${color_reset}"
echo -e "User: ${color_bold}${color_yellow}$USER${color_reset}"
echo -e "Home Directory: ${color_bold}${color_yellow}$HOME${color_reset}"
echo ""
echo -e "This machine's timezone is ${color_bold}${color_green}$timezone${color_reset}"
echo -e "The current time is ${color_bold}${color_green}$current_time${color_reset}"
echo -e "${color_bold}-----------------------------------------------------------------------${color_reset}"






