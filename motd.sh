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
cpu=$(cat /proc/cpuinfo | grep -m1 'model name' | cut -d':' -f2 | sed 's/^ *//')
gpu=$(lspci | grep -i 'VGA' | cut -d':' -f3 | sed 's/^ *//')
ram_percentage=$(free | awk '/^Mem:/ {print $3/$2 * 100}')
ram=$(free -h | awk '/^Mem:/ {print $3 "/" $2}')
storage_total=$(df -BM / | awk '/\// {print $2}')
storage_used=$(df -BM / | awk '/\// {print $3}')
storage_percentage=$(df -BM / | awk '/\// {print $5}')

package_managers=("apt-get" "yum" "dnf" "zypper" "pacman" "apk" "emerge")

if ! command -v bc >/dev/null 2>&1; then
    echo "bc is not installed. Installing..."

    installed=false

    for manager in "${package_managers[@]}"; do
        if command -v "$manager" >/dev/null 2>&1; then
            sudo "$manager" install -y bc
            installed=true
            break
        fi
    done

    if ! "$installed"; then
        echo "Unsupported package manager. Please install bc manually."
        exit 1
    fi
fi
if ! command -v lolcat >/dev/null 2>&1; then
    echo "lolcat is not installed. Installing..."

    installed=false

    for manager in "${package_managers[@]}"; do
        if command -v "$manager" >/dev/null 2>&1; then
            sudo "$manager" install -y lolcat
            installed=true
            break
        fi
    done

    if ! "$installed"; then
        echo "Unsupported package manager. Please install lolcat manually."
        exit 1
    fi
fi
# Define color codes
color_reset="\e[0m"          # reset color
color_bold="\e[1m"           # bold
color_yellow="\e[33m"        # yellow
color_red="\e[31m"           # red
color_orange="${color_red}${color_yellow}"  # orange (approximation)
color_blue="\e[34m"          # blue
color_green="\e[32m"         # green
color_magenta="\e[35m"       # magenta/purple
color_cyan="\e[36m"          # cyan
color_light_gray="\e[37m"    # light gray
color_dark_gray="\e[90m"     # dark gray
color_light_red="\e[91m"     # light red
color_light_green="\e[92m"   # light green
color_light_yellow="\e[93m"  # light yellow
color_light_blue="\e[94m"    # light blue
color_light_magenta="\e[95m" # light magenta
color_light_cyan="\e[96m"    # light cyan
color_white="\e[97m"         # white
logo=$(cat << "EOF"
 __          __  ______   _         _____    ____    __  __   ______   _
 \ \        / / |  ____| | |       / ____|  / __ \  |  \/  | |  ____| | |
  \ \  /\  / /  | |__    | |      | |      | |  | | | \  / | | |__    | |
   \ \/  \/ /   |  __|   | |      | |      | |  | | | |\/| | |  __|   | |
    \  /\  /    | |____  | |____  | |____  | |__| | | |  | | | |____  |_|
     \/  \/     |______| |______|  \_____|  \____/  |_|  |_| |______| (_)
EOF
)

# Print the welcome message with the ASCII
echo -e "${color_bold}$logo${color_reset}" | lolcat

echo -e "${color_bold}-----------------------------------------------------------------------${color_reset}"
echo -e "Welcome to ${color_bold}Gummi's MacBook Air!${color_reset}"
echo -e "This machine is running ${color_bold}${color_blue}Arch Linux${color_reset},"
echo -e "a ${color_bold}standalone Linux Distribution${color_reset}"
echo ""
echo -e "Hostname: ${color_bold}${color_green}$hostname${color_reset}"
echo -e "Kernel Version: ${color_bold}${color_green}$kernel_version${color_reset}"
echo -e "CPU Architecture: ${color_bold}${color_green}$architecture${color_reset}"
echo -e "User: ${color_bold}${color_yellow}$USER${color_reset}"
echo -e "Home Directory: ${color_bold}${color_yellow}$HOME${color_reset}"
echo ""
echo -e "CPU: ${color_bold}${color_green}$cpu${color_reset}"
echo -e "GPU: ${color_bold}${color_green}$gpu${color_reset}"

# Set color based on RAM usage percentage
if (( $(echo "$ram_percentage >= 85" | bc -l) )); then
    ram_color="${color_red}"
elif (( $(echo "$ram_percentage >= 65" | bc -l) )); then
    ram_color="${color_yellow}"
else
    ram_color="${color_green}"
fi

echo -e "RAM Usage: ${color_bold}${ram_color}$ram${color_reset}"
echo -e "Storage Usage: ${color_bold}${color_green}$storage_used / $storage_total ($storage_percentage)${color_reset}"
echo ""
echo -e "This machine's timezone is ${color_bold}${color_green}$timezone${color_reset}"
echo -e "The current time is ${color_bold}${color_green}$current_time${color_reset}"
echo -e "${color_bold}-----------------------------------------------------------------------${color_reset}"
