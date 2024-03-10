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

# Check if bc is installed
if ! command -v bc >/dev/null 2>&1; then
    echo "bc is not installed. Installing..."

    # Try installing using package managers
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y bc
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y bc
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y bc
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y bc
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm bc
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add bc
    elif command -v emerge >/dev/null 2>&1; then
	sudo emerge sys-devel/bc
    else
        echo "Unsupported package manager. Please install bc manually."
        exit 1
    fi
fi
if ! command -v lolcat >/dev/null 2>&1; then
    echo "lolcat is not installed. Installing..."

    # Try installing using package managers
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get install -y lolcat
    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y lolcat
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y lolcat
    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y lolcat
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm lolcat
    elif command -v apk >/dev/null 2>&1; then
        sudo apk add lolcat
    elif command -v emerge >/dev/null 2>&1; then
        sudo emerge lolcat
    else
        echo "Unsupported package manager. Please install lolcat manually."
        exit 1
    fi

fi

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
