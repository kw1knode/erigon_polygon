#!/bin/bash

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
Description=Erigon Polygon Service
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
Restart=on-failure
RestartSec=5
TimeoutSec=900
User=root
Nice=0
LimitNOFILE=200000
WorkingDirectory=/usr/local/bin/erigon/
ExecStart=/usr/local/bin/erigon/build/bin/erigon \\
        --chain=bor-mainnet \\
        --datadir=/var/lib/erigon \\
        --ethash.dagdir=/var/lib/erigon/ethash \\
        --snapshots=false \\
        --snap.stop \\
        --bor.heimdall=http://localhost:1317 \\
        --http --http.addr=0.0.0.0 --http.port=9656 \\
        --http.compression --http.vhosts=* --http.corsdomain=* \\
        --http.api=eth,debug,net,trace,web3,erigon,bor \
        --ws --ws.compression \\
        --rpc.gascap=300000000 \\
        --metrics --metrics.addr=0.0.0.0 --metrics.port=6060 \\
        --bodies.cache=5G --rpc.batch.limit=200000 \\
        --db.pagesize=16k \\
        --batchSize=2048MB \\
        --p2p.protocol=66 \\
        --rpc.returndata.limit=1000000

KillSignal=SIGHUP

[Install]
WantedBy=multi-user.target" | sudo tee -a  /etc/systemd/system/erigon.service > /dev/null


sudo systemctl daemon-reload
