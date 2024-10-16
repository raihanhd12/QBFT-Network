#!/bin/bash

# Fungsi untuk mendapatkan IP publik
get_public_ip() {
    public_ip=$(curl -s ifconfig.me)
    echo "Your public IP is: $public_ip"
}

# Fungsi untuk mendapatkan IP lokal
get_local_ip() {
    local_ip=$(hostname -I | awk '{print $1}') # Mengambil IP pertama
    echo "Your local IP is: $local_ip"
}

# Memanggil fungsi
get_public_ip
get_local_ip
