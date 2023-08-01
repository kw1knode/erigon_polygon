#!/bin/bash

#####################################################################################
################################### PREQUISITES #####################################
#####################################################################################

apt update -y && apt upgrade -y && apt autoremove -y
sudo apt-get install -y build-essential ufw
sudo mkdir -p /var/lib/jwtsecret
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret/jwt.hex > /dev/null

#####################################################################################
################################## FIREWALL #########################################
#####################################################################################

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 30303 #Allow Erigon P2P
sudo ufw allow 9000  #Allow Prysm P2P
sudo ufw allow 22/tcp #Allow SSH
sudo ufw enable

#####################################################################################
################################## GOLANG ###########################################
#####################################################################################

cd ~
curl -LO https://go.dev/dl/go1.20.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz
echo 'PATH="$PATH:/usr/local/go/bin"' >> $HOME/.profile
source $HOME/.profile
rm go1.20.3.linux-amd64.tar.gz

#####################################################################################
################################## INSTALL ERIGON ###################################
#####################################################################################
cd ~
curl -LO https://github.com/ledgerwatch/erigon/archive/refs/tags/v2.48.1.tar.gz
tar xvf v2.48.1.tar.gz
cd erigon-2.48.1
make erigon
cd ~
sudo cp -a erigon-2.48.1 /usr/local/bin/erigon
rm v2.48.1.tar.gz
rm -r erigon-2.48.1
sudo useradd --no-create-home --shell /bin/false erigon
sudo mkdir -p /var/lib/erigon
sudo chown -R erigon:erigon /var/lib/erigon

#####################################################################################
################################# ERIGON SERVICE ####################################
#####################################################################################
echo -e "[Unit]
Description=Erigon Execution Client (Mainnet)
After=network.target
Wants=network.target
[Service]
User=erigon
Group=erigon
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/erigon/build/bin/erigon \\
  --datadir=/var/lib/erigon \\
  --rpc.gascap=50000000 \\
  --http \\
  --ws \\
  --rpc.batch.concurrency=100 \\
  --state.cache=2000000 \\
  --http.addr="0.0.0.0" \\
  --http.port=8545 \\
  --http.api="eth,erigon,web3,net,debug,trace,txpool" \\
  --rpc.returndata.limit=1000000 \\
  --rpc.batch.limit=1000 \\
  --authrpc.port=8551 \\
  --private.api.addr="0.0.0.0:9595" \\
  --http.corsdomain="*" \\
  --torrent.download.rate 90m \\
  --externalcl \\
  --authrpc.jwtsecret=/var/lib/jwtsecret/jwt.hex \\
  --metrics \\
  --metrics.port=6868
KillSignal=SIGHUP
[Install]
WantedBy=default.target" | sudo tee -a  /etc/systemd/system/erigon.service

#####################################################################################
################################ INSTALL PRYSM ######################################
#####################################################################################

cd ~
curl -LO https://github.com/prysmaticlabs/prysm/releases/download/v4.0.7/beacon-chain-v4.0.7-linux-amd64
mv beacon-chain-v4.0.1-linux-amd64 beacon-chain
chmod +x beacon-chain
sudo cp beacon-chain /usr/local/bin
rm beacon-chain
sudo useradd --no-create-home --shell /bin/false prysmbeacon
sudo mkdir -p /var/lib/prysm/beacon 
sudo chown -R prysmbeacon:prysmbeacon /var/lib/prysm/beacon

#####################################################################################
################################ PRYSM SERVICE ######################################
#####################################################################################

echo -e "[Unit]
Description=Prysm Consensus Client (Mainnet)
Wants=network-online.target
After=network-online.target
[Service]
User=prysmbeacon
Group=prysmbeacon
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/beacon-chain \
  --mainnet \
  --datadir=/var/lib/prysm/beacon \
  --execution-endpoint=http://127.0.0.1:8551 \
  --jwt-secret=/var/lib/jwtsecret/jwt.hex \
  --checkpoint-sync-url=https://sync-mainnet.beaconcha.in \
  --genesis-beacon-api-url=https://sync-mainnet.beaconcha.in \
  --accept-terms-of-use
[Install]
WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/prysm.service

#####################################################################################
###################################### START ########################################
#####################################################################################

sudo systemctl daemon-reload
sleep 2
sudo systemctl start erigon
sleep 10
sudo systemctl start prysmbeacon

#sudo systemctl enable erigon #START AFTER REBOOT
#sudo systemctl enable prysm #START AFTER REBOOT
