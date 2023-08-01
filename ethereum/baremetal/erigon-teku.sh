#!/bin/bash

#####################################################################################
################################### PREQUISITES #####################################
#####################################################################################

apt update -y && apt upgrade -y && apt autoremove -y
sudo apt-get install -y build-essential ufw openjdk-17-jre
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
################################## INSTALL TEKU #####################################
#####################################################################################

cd ~
curl -LO https://artifacts.consensys.net/public/teku/raw/names/teku.tar.gz/versions/23.6.2/teku-23.6.2.tar.gz
tar xvf teku-23.6.2.tar.gz
sudo cp -a teku-23.6.2 /usr/local/bin/teku
rm teku-23.3.1.tar.gz
rm -r teku-23.3.1
sudo useradd --no-create-home --shell /bin/false teku
sudo mkdir -p /var/lib/teku
sudo chown -R teku:teku /var/lib/teku

#####################################################################################
################################# TEKU SERVICE ######################################
#####################################################################################

echo -e "[Unit]
Description=Teku Consensus Client (Mainnet)
Wants=network-online.target
After=network-online.target
[Service]
User=teku
Group=teku
Type=simple
Restart=always
RestartSec=5
Environment="JAVA_OPTS=-Xmx5g"
Environment="TEKU_OPTS=-XX:-HeapDumpOnOutOfMemoryError"
ExecStart=/usr/local/bin/teku/bin/teku \
  --network=mainnet \
  --data-path=/var/lib/teku \
  --ee-endpoint=http://127.0.0.1:8551 \
  --ee-jwt-secret-file=/var/lib/jwtsecret/jwt.hex \
  --initial-state=https://sync-mainnet.beaconcha.in \
  --metrics-enabled=true 
[Install]
WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/teku.service

#####################################################################################
###################################### START ########################################
#####################################################################################

sudo systemctl daemon-reload
sleep 2
sudo systemctl start erigon
sleep 10
sudo systemctl start teku

#sudo systemctl enable erigon #START AFTER REBOOT
#sudo systemctl enable teku #START AFTER REBOOT
