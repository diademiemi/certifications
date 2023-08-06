#!/bin/bash

# Check if /mnt/output/ exists
if 
    [ ! -d "/mnt/output/" ]; then
    echo "Directory /mnt/output/ does not exist. Creating it now..."
    mkdir -p /mnt/output/
fi

# Check if /mnt/output/date file exists
if 
    [ ! -f "/mnt/output/date" ]; then
    echo "File /mnt/output/date does not exist. Creating it now..."
    date > /mnt/output/date
fi

exit 0
