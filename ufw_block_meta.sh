#!/bin/bash

# Check if subnets.txt exists
if [ ! -f "subnets.txt" ]; then
    echo "Error: subnets.txt not found!"
    exit 1
fi

# Check if script is run with sudo/root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script with sudo or as root"
    exit 1
fi

# Check if ufw is installed
if ! command -v ufw &> /dev/null; then
    echo "Error: UFW is not installed!"
    exit 1
fi

# Counter for blocked subnets
count=0

# Read subnets.txt line by line
while IFS= read -r subnet; do
    # Skip empty lines and comments
    [[ -z "$subnet" || "$subnet" =~ ^# ]] && continue
    
    # Trim whitespace
    subnet=$(echo "$subnet" | xargs)
    
    # Validate CIDR format (basic check)
    if [[ "$subnet" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+$ ]]; then
        # Add UFW rule to deny traffic from this subnet
        ufw deny from "$subnet" && {
            echo "Blocked: $subnet"
            ((count++))
        } || {
            echo "Error blocking: $subnet"
        }
    else
        echo "Invalid CIDR format skipped: $subnet"
    fi
done < "subnets.txt"

echo "Finished! Blocked $count subnets."
