#!/usr/bin/env bash
THRESHOLD=10 

while true; do
    for f in ~/.last_term_activity_*; do
        [[ -f "$f" ]] || continue
        last=$(cat "$f")
        now=$(date +%s)
        if (( now - last > THRESHOLD )); then
            term=$(echo "$f" | sed "s#_dev_##" | tr "_" "/")
            echo "clear; tclock" > "$term"
            rm -f "$f"
        fi
    done
    sleep 5
done

