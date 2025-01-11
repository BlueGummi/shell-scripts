#!/bin/bash

dir=$(pwd)

while [ "$dir" != "/" ]; do
    if [ -f "$dir/Makefile" ] || [ -f "$dir/makefile" ]; then
        make -C "$dir" "$@"
        exit 0
    fi
    dir=$(dirname "$dir")
done

echo "No Makefile found."
exit 1
