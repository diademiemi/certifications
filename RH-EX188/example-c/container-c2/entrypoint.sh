#!/bin/bash


while true; do 
# Check if /mnt/output/date file exists
    if 
        [ -f "/mnt/output/date" ]; then
        echo "File /mnt/output/date exists. Reading it:"
        cat /mnt/output/date
        exit 0
    fi
    sleep 5
done
