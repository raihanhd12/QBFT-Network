#!/bin/bash

# Fungsi untuk menghapus semua folder kecuali yang diizinkan
cleanup() {
    # Directories and files to keep
    KEEP_DIRS=("scripts" "quorum-explorer")

    # Remove all directories except the ones in KEEP_DIRS
    echo "Removing existing directories and files except for scripts and quorum-explorer..."
    for item in *; do
        if [[ ! " ${KEEP_DIRS[@]} " =~ " ${item} " ]]; then
            echo "Removing $item"
            rm -rf "$item"
        fi
    done
}

# Fungsi untuk mengkonversi ether ke wei
convert_to_wei() {
    local ether=$1
    local wei=$(echo "$ether * 1000000000000000000" | bc)
    echo $wei
}

# Fungsi untuk membuat file konfigurasi dengan konfigurasi default
create_default_config() {
    CURRENT_TIMESTAMP=$(printf '0x%x\n' $(date +%s))

    cat <<EOL > qbftConfigFile.json
{
"genesis": {
    "config": {
        "chainId": 1337,
        "berlinBlock": 0,
        "contractSizeLimit": 2147483647,
        "qbft": {
            "blockperiodseconds": 5,
            "epochlength": 30000,
            "requesttimeoutseconds": 10
        }
    },
    "nonce": "0x0",
    "timestamp": "0x66d810bf",
    "gasLimit": "0x1fffffffffffff",
    "difficulty": "0x1",
    "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
    "coinbase": "0x0000000000000000000000000000000000000000",
    "alloc": {
        "fe3b557e8fb62b89f4916b721be55ceb828dbd73": {
          "privateKey": "8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63",
          "comment": "private key and this comment are ignored.  In a real chain, the private key should NOT be stored",
          "balance": "0xad78ebc5ac6200000"
        },
        "627306090abaB3A6e1400e9345bC60c78a8BEf57": {
          "privateKey": "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3",
          "comment": "private key and this comment are ignored.  In a real chain, the private key should NOT be stored",
          "balance": "90000000000000000000000"
        },
        "f17f52151EbEF6C7334FAD080c5704D77216b732": {
          "privateKey": "ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f",
          "comment": "private key and this comment are ignored.  In a real chain, the private key should NOT be stored",
          "balance": "90000000000000000000000"
        }
      }
},
"blockchain": {
    "nodes": {
        "generate": true,
        "count": 4
    }
}
}

EOL
    echo "Default configuration created."
}

# Fungsi untuk membuat file konfigurasi berdasarkan input pengguna
create_custom_config() {
    read -p "Enter chainId: " chainId
    read -p "Select consensus mechanism (ibft, qbft, clique): " consensus
    read -p "Enter block period seconds: " blockPeriodSeconds
    requestTimeoutSeconds=$((blockPeriodSeconds * 2))
    read -p "Enter the number of accounts to allocate: " numAlloc

    addresses=()
    balances=()

    for ((i = 1; i <= numAlloc; i++)); do
        while true; do
            read -p "Enter address for account $i: " address
            address=${address#0x} # Remove leading 0x if present
            if [[ " ${addresses[@]} " =~ " ${address} " ]]; then
                echo "Address $address has already been added. Please enter a different address."
            else
                addresses+=($address)
                break
            fi
        done
        read -p "Enter balance (in ether) for account $i: " balance
        balances+=($(convert_to_wei $balance))
    done

    read -p "Enter the number of nodes: " numNodes

    CURRENT_TIMESTAMP=$(printf '0x%x\n' $(date +%s))

    cat <<EOL > qbftConfigFile.json
{
    "genesis": {
        "config": {
            "chainId": $chainId,
            "berlinBlock": 0,
            "contractSizeLimit": 2147483647,
            "$consensus": {
                "blockperiodseconds": $blockPeriodSeconds,
                "epochlength": 30000,
                "requesttimeoutseconds": $requestTimeoutSeconds
            }
        },
        "nonce": "0x0",
        "timestamp": "$CURRENT_TIMESTAMP",
        "gasLimit": "0x1fffffffffffff",
        "difficulty": "0x1",
        "mixHash": "0x63746963616c2062797a616e74696e65206661756c7420746f6c6572616e6365",
        "coinbase": "0x0000000000000000000000000000000000000000",
        "alloc": {
EOL

    for ((i = 0; i < ${#addresses[@]}; i++)); do
        if (( i == ${#addresses[@]} - 1 )); then
            cat <<EOL >> qbftConfigFile.json
            "${addresses[$i]}": {
                "balance": "${balances[$i]}"
            }
EOL
        else
            cat <<EOL >> qbftConfigFile.json
            "${addresses[$i]}": {
                "balance": "${balances[$i]}"
            },
EOL
        fi
    done

    cat <<EOL >> qbftConfigFile.json
        }
    },
    "blockchain": {
        "nodes": {
            "generate": true,
            "count": $numNodes
        }
    }
}
EOL
    echo "Custom configuration created."
}

# Main script execution
echo "Do you want to use the default configuration? (yes/no)"
read useDefault

if [[ "$useDefault" == "yes" ]]; then
    cleanup
    create_default_config
else
    cleanup
    create_custom_config
fi

echo "Setup complete!"
