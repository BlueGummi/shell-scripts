#!/bin/bash
current_date=$(date +"%d")
current_month=$(date +"%B")
current_year=$(date +"%Y")
current_date=$((10#$current_date))
ordinal_suffix() {
    case $1 in
        1|21|31) echo "st" ;;
        2|22) echo "nd" ;;
        3|23) echo "rd" ;;
        *) echo "th" ;;
    esac
}
suffix=$(ordinal_suffix $current_date)

echo "$current_month $current_date$suffix"
