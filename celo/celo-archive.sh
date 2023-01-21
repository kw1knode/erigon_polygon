#!/bin/bash

#celo version
celo_version=v1.7.2

#install Dependencies
sudo apt install -y git make wget gcc pkg-config libusb-1.0-0-dev \
libudev-dev jq gcc g++ curl libssl-dev apache2-utils build-essential pkg-config

#install go
cd ~
curl -LO https://go.dev/dl/go1.19.linux-amd64.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf go1.19.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
source $HOME/.profile
rm go1.19.linux-amd64.tar.gz

#Install Celo
git clone https://github.com/celo-org/celo-blockchain
cd celo-blockchain
git checkout $celo_version
make
sudo cp -a $HOME/celo-blockchain/build /usr/local/bin

#User & Permissions
sudo useradd --no-create-home --shell /bin/false celo
sudo mkdir -p /var/lib/celo
sudo chown -R celo:celo /var/lib/celo

#Service File
echo -e "sudo echo "[Unit]
Description=Celo Archive Node
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
Restart=on-failure
RestartSec=5
TimeoutSec=900
User=celo
Nice=0
LimitNOFILE=200000
WorkingDirectory=/root/celo-blockchain
ExecStart=/root/celo-blockchain/build/bin/geth \\
   --datadir=/root/.local/share/celo/datadir \\
   --syncmode=full \\
   --gcmode=archive \\
   --txlookuplimit=0 \\
   --cache.preimages \\
   --port=9656 \\
   --http \\
   --http.addr=0.0.0.0 \\
   --http.api=eth,net,web3,debug,admin,personal

KillSignal=SIGHUP

[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/celo.service

sudo systemctl daemon-reload
sudo systemctl enable celo
sudo systemctl start celo

				
