#!/bin/bash

function validate_network() {
  if [[ "$1" != "mainnet" && "$1" != "mumbai" ]]; then
    echo "Invalid network input. Please enter 'mainnet' or 'mumbai'."
    exit 1
  fi
}

function validate_client() {
  if [[ "$1" != "heimdall" && "$1" != "bor" && "$1" != "erigon" ]]; then
    echo "Invalid client input. Please enter 'heimdall' or 'bor' or 'erigon'."
    exit 1
  fi
}

function validate_checksum() {
  if [[ "$1" != "true" && "$1" != "false" ]]; then
    echo "Invalid checksum input. Please enter 'true' or 'false'."
    exit 1
  fi
}

# ask user for network and client type
read -p "PoSV1 Network (mainnet/mumbai): " network_input
validate_network "$network_input"
read -p "Client Type (heimdall/bor/erigon): " client_input
validate_client "$client_input"
read -p "Directory to Download/Extract: " extract_dir_input
read -p "Perform checksum verification (true/false): " checksum_input
validate_checksum "$checksum_input"

# set default values if user input is blank
network=${network_input:-mumbai}
client=${client_input:-heimdall}
extract_dir=${extract_dir_input:-"${client}_extract"}
checksum=${checksum_input:-false}

# temporary as we transition erigon mainnet snapshots to new incremental model, ETA Aug 2023
if [[ "$client" == "erigon" && "$network" == "mainnet" ]]; then
  echo "Erigon bor-mainnet archive snapshots currently unavailable as we transition to incremental snapshot model. ETA Aug 2023."
  exit 1
fi

# install dependencies and cursor to extract directory
sudo apt-get update -y
sudo apt-get install -y zstd pv aria2
mkdir -p "$extract_dir"
cd "$extract_dir"

# download compiled incremental snapshot files list
aria2c -x6 -s6 "https://snapshot-download.polygon.technology/$client-$network-incremental-compiled-files.txt"

# remove hash lines if user declines checksum verification
if [ "$checksum" == "false" ]; then
    sed -i '/checksum/d' $client-$network-incremental-compiled-files.txt
fi

# download all incremental files, includes automatic checksum verification per increment
aria2c -x6 -s6 -c --auto-file-renaming=false --max-tries=100 -i $client-$network-incremental-compiled-files.txt

# Don't extract if download failed
if [ $? -ne 0 ]; then
    echo "Download failed. Restart the script to resume downloading."
    exit 1
fi

# helper method to extract all files and delete already-extracted download data to minimize disk use
function extract_files() {
    compiled_files=$1
    while read -r line; do
        if [[ "$line" == checksum* ]]; then
            continue
        fi
        filename=`echo $line | awk -F/ '{print $NF}'`
        if echo "$filename" | grep -q "bulk"; then
            pv $filename | tar -I zstd -xf - -C . && rm $filename
        else
            pv $filename | tar -I zstd -xf - -C . --strip-components=3 && rm $filename
        fi
    done < $compiled_files
}

# execute final data extraction step
extract_files $client-$network-incremental-compiled-files.txt