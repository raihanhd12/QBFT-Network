#!/bin/bash

BASE_IP_FILE="base_ip.txt" 

# Function to get base IP
get_base_ip() {
    if [ -f "$BASE_IP_FILE" ]; then
        BASE_IP=$(cat "$BASE_IP_FILE")
        echo "Using saved BASE_IP: $BASE_IP"
    else
        # Prompt user to select IP type
        echo "Select IP type to use for nodes:"
        echo "1) Public IP"
        echo "2) Local IP"
        read -p "Enter your choice (1 or 2): " choice

        if [ "$choice" -eq 1 ]; then
            BASE_IP=$(curl -s ifconfig.me)  # Get public IP
            echo "Using Public IP: $BASE_IP"
        elif [ "$choice" -eq 2 ]; then
            BASE_IP=$(hostname -I | awk '{print $1}')  # Get local IP
            echo "Using Local IP: $BASE_IP"
        else
            echo "Invalid choice. Exiting."
            exit 1
        fi

        # Save the BASE_IP to the base_ip.txt file
        echo "$BASE_IP" > "$BASE_IP_FILE"
        echo "Saved BASE_IP to $BASE_IP_FILE"
    fi
}

# Get the base IP
get_base_ip

if [ -z "$1" ]; then
    echo "Usage: $0 <Node-X>"
    exit 1
fi

NODE_DIR="$1"
NODE_NUMBER=$(echo $NODE_DIR | grep -o '[0-9]*')
RPC_HTTP_PORT=$((8545 + NODE_NUMBER - 1))
RPC_URL="http://${BASE_IP}:${RPC_HTTP_PORT}"

# JSON-RPC request payload
PAYLOAD='{"jsonrpc":"2.0","method":"qbft_getValidatorsByBlockNumber","params":["latest"], "id":1}'

# Make the JSON-RPC API call using curl and parse the response using jq
RESPONSE=$(curl -s -X POST --data "$PAYLOAD" $RPC_URL | jq)

if [ -z "$RESPONSE" ]; then
    echo "Node $NODE_DIR ($RPC_URL) is stopped or not responding."
    exit 1
fi

# Display the response
echo "Response from JSON-RPC API for $NODE_DIR ($RPC_URL):"
echo "$RESPONSE"

# Extract and count the number of validators
VALIDATORS=$(echo "$RESPONSE" | jq '.result | length')

echo "Number of validators for $NODE_DIR: $VALIDATORS"

# Confirm the network has at least four validators
if [ "$VALIDATORS" -ge 4 ]; then
    echo "The private network is working correctly with at least four validators for $NODE_DIR."
else
    echo "The private network does not have four validators for $NODE_DIR."
fi
