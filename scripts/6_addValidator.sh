#!/bin/bash

LOG_DIR="logs"
BOOTNODES_FILE="bootnodes.txt"
GENESIS_FILE="genesis.json"
NODE_ADDRESS_DIR="NodeAddresses"
CONFIG_FILE="quorum-explorer/src/config/config.json"
BASE_IP_FILE="base_ip.txt"  # Tempat menyimpan BASE_IP

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

# Create log directory if it doesn't exist
mkdir -p "${LOG_DIR}"
mkdir -p "${NODE_ADDRESS_DIR}"

# Function to find available port
find_available_port() {
  local PORT=$1
  while lsof -i :${PORT} >/dev/null; do
    PORT=$((PORT + 1))
  done
  echo ${PORT}
}

# Determine the next node directory and ports
NODE_COUNTER=1
while [ -d "Node-${NODE_COUNTER}" ]; do
    NODE_COUNTER=$((NODE_COUNTER + 1))
done

NODE_DIR="Node-${NODE_COUNTER}"
P2P_PORT=$(find_available_port $((30303 + $((NODE_COUNTER - 1)))))
RPC_HTTP_PORT=$(find_available_port $((8545 + $((NODE_COUNTER - 1)))))

# Ensure the node directory exists and create data subdirectory
mkdir -p "${NODE_DIR}/data"

# Start the new validator node
echo "Starting new validator node (Node-${NODE_COUNTER}) with P2P port ${P2P_PORT} and RPC HTTP port ${RPC_HTTP_PORT}..."
nohup besu --data-path="${NODE_DIR}/data" \
     --genesis-file="${GENESIS_FILE}" \
     --bootnodes="$(cat $BOOTNODES_FILE)" \
     --p2p-port=${P2P_PORT} \
     --rpc-http-enabled \
     --rpc-http-api=EEA,WEB3,ETH,NET,TRACE,DEBUG,ADMIN,TXPOOL,PERM,QBFT \
     --host-allowlist="*" \
     --rpc-http-port=${RPC_HTTP_PORT} \
     --rpc-http-cors-origins="*" \
     --rpc-http-host="${BASE_IP}" \
     --min-gas-price=0 > "${LOG_DIR}/node${NODE_COUNTER}.log" 2>&1 &

# Wait for the node to start
sleep 10

# Capture the enode URL from the log file (but do not write it to bootnodes.txt)
ENODE_URL=$(grep -m 1 -o "enode://[^@]*@[^:]*:[0-9]*" "${LOG_DIR}/node${NODE_COUNTER}.log")

if [ -z "$ENODE_URL" ]; then
    echo "Failed to capture enode URL for the new validator node."
    echo "Log content for debugging:"
    cat "${LOG_DIR}/node${NODE_COUNTER}.log"
    exit 1
fi

echo "New validator node started with enode URL: $ENODE_URL"

# Capture the node address from the log file
NODE_ADDRESS=$(grep -m 1 -o "Node address [^ ]*" "${LOG_DIR}/node${NODE_COUNTER}.log" | awk '{print $3}')

# Save the node address to the NodeAddresses directory
echo "$NODE_ADDRESS" > "${NODE_ADDRESS_DIR}/Node-${NODE_COUNTER}.address"

# Debugging output to check if NODE_ADDRESS is empty
if [ -z "$NODE_ADDRESS" ]; then
    echo "Node address not found in the log file. Here is the log content:"
    cat "${LOG_DIR}/node${NODE_COUNTER}.log"
    echo "Failed to capture node address for the new validator node."
    exit 1
fi

echo "New validator node address: $NODE_ADDRESS"

# Get all existing node directories and calculate the majority
EXISTING_NODE_COUNT=$((NODE_COUNTER - 1))
MAJORITY_COUNT=$(( (EXISTING_NODE_COUNT / 2) + 1 ))

# Propose adding the new validator from a majority of existing nodes
echo "Proposing new validator from ${MAJORITY_COUNT} nodes..."
VALIDATOR_VOTE_COUNT=0
for i in $(seq 1 $EXISTING_NODE_COUNT); do
    if [ $VALIDATOR_VOTE_COUNT -ge $MAJORITY_COUNT ]; then
        break
    fi
    RPC_PORT=$((8544 + i))
    echo "Proposing new validator from node with RPC port ${RPC_PORT}..."

    # Adding detailed logging to capture any issues with the RPC request
    RESPONSE=$(curl -s -m 30 -X POST --data '{"jsonrpc":"2.0","method":"qbft_proposeValidatorVote","params":["'"${NODE_ADDRESS}"'", true], "id":1}' http://${BASE_IP}:${RPC_PORT})

    if [ -z "$RESPONSE" ]; then
        echo "No response from node with RPC port ${RPC_PORT}. Possible connection issue."
    else
        echo "Response from node with RPC port ${RPC_PORT}: $RESPONSE"
    fi

    if echo "$RESPONSE" | grep -q '"result":true'; then
        VALIDATOR_VOTE_COUNT=$((VALIDATOR_VOTE_COUNT + 1))
        echo "Validator vote succeeded from node with RPC port ${RPC_PORT}."
    else
        echo "Validator vote failed from node with RPC port ${RPC_PORT}. Response: $RESPONSE"
    fi
    echo ""
done

if [ $VALIDATOR_VOTE_COUNT -ge $MAJORITY_COUNT ]; then
    echo "New validator node added successfully (Node-${NODE_COUNTER})."
else
    echo "Failed to get majority vote for the new validator node (Node-${NODE_COUNTER})."
    exit 1
fi

# Find the highest validator number in the config file
HIGHEST_VALIDATOR_NUMBER=$(jq -r '.nodes[] | select(.name | test("^validator[0-9]+$")) | .name' ${CONFIG_FILE} | sed 's/validator//' | sort -n | tail -1)
if [ -z "$HIGHEST_VALIDATOR_NUMBER" ]; then
    HIGHEST_VALIDATOR_NUMBER=0
fi

# Check if the new validator already exists in the config file
EXISTING_VALIDATOR=$(jq --arg rpcUrl "http://${BASE_IP}:${RPC_HTTP_PORT}" '.nodes[] | select(.rpcUrl == $rpcUrl)' ${CONFIG_FILE})

if [ -n "$EXISTING_VALIDATOR" ]; then
    echo "Validator with rpcUrl http://${BASE_IP}:${RPC_HTTP_PORT} already exists in the config file."
else
    NEW_VALIDATOR_NUMBER=$((HIGHEST_VALIDATOR_NUMBER + 1))
    # Update config.json for Quorum Explorer
    jq --arg name "validator${NEW_VALIDATOR_NUMBER}" --arg rpcUrl "http://${BASE_IP}:${RPC_HTTP_PORT}" \
       '.nodes += [{"name": $name, "client": "besu", "rpcUrl": $rpcUrl, "privateTxUrl": ""}]' \
       ${CONFIG_FILE} > tmp.$$.json && mv tmp.$$.json ${CONFIG_FILE}
    echo "Updated Quorum Explorer config with new validator node validator${NEW_VALIDATOR_NUMBER}."
fi
