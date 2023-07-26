#!/bin/bash
apt update -y && apt upgrade -y && apt autoremove -y

### GO
cd ~
curl -LO https://go.dev/dl/go1.20.3.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.20.3.linux-amd64.tar.gz
echo 'PATH="$PATH:/usr/local/go/bin"' >> $HOME/.profile
source $HOME/.profile
rm go1.20.3.linux-amd64.tar.gz

### PREREQ
sudo apt-get install -y build-essential
sudo mkdir -p /var/lib/jwtsecret
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret/jwt.hex > /dev/null

### ERIGON
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

### ERIGON SERVICE
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

### LIGHTHOUSE BEACON
cd ~
curl -LO https://github.com/sigp/lighthouse/releases/download/v4.3.0/lighthouse-v4.3.0-x86_64-unknown-linux-gnu.tar.gz
tar xvf lighthouse-v4.3.0-x86_64-unknown-linux-gnu.tar.gz
sudo cp lighthouse /usr/local/bin
rm lighthouse-v4.3.0-x86_64-unknown-linux-gnu.tar.gz
rm lighthouse
sudo useradd --no-create-home --shell /bin/false lighthousebeacon
sudo mkdir -p /var/lib/lighthouse/beacon
sudo chown -R lighthousebeacon:lighthousebeacon /var/lib/lighthouse/beacon

### LIGHTHOUSE SERVICE
echo -e "[Unit]
Description=Lighthouse Consensus Client (Mainnet)
Wants=network-online.target
After=network-online.target
[Service]
User=lighthousebeacon
Group=lighthousebeacon
Type=simple
Restart=always
RestartSec=5
ExecStart=/usr/local/bin/lighthouse bn \\
  --network mainnet \\
  --datadir /var/lib/lighthouse \\
  --http \\
  --execution-endpoint http://127.0.0.1:8551 \\
  --execution-jwt /var/lib/jwtsecret/jwt.hex \\
  --checkpoint-sync-url https://beaconstate.info \\
  --genesis-beacon-api-url https://beaconstate.info
KillSignal=SIGHUP
[Install]
WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/lighthouse.service

sudo systemctl daemon-reload
sleep 2
sudo systemctl start erigon
sleep 10
sudo systemctl start lighthouse
