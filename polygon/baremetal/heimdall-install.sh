#!/bin/bash

#####################################################################################
################################### PREQUISITES #####################################
#####################################################################################

apt update -y && apt upgrade -y && apt autoremove -y
sudo apt-get install -y build-essential ufw
sudo mkdir -p /var/lib/jwtsecret
openssl rand -hex 32 | sudo tee /var/lib/jwtsecret/jwt.hex > /dev/null

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
################################# INSTALL HEIMDALL  #################################
#####################################################################################

git clone -b v0.3.4 https://github.com/maticnetwork/heimdall
cd heimdall
make build network=mainnet
$HOME/heimdall/build/heimdalld init 
cd $HOME/.heimdalld
wget -O $HOME/.heimdalld/config/genesis.json https://raw.githubusercontent.com/maticnetwork/launch/master/mainnet-v1/without-sentry/heimdall/config/genesis.json
sed -i '/^seeds/c\seeds = "f4f605d60b8ffaaf15240564e58a81103510631c@159.203.9.164:26656,4fb1bc820088764a564d4f66bba1963d47d82329@44.232.55.71:26656,2eadba4be3ce47ac8db0a3538cb923b57b41c927@35.199.4.13:26656,3b23b20017a6f348d329c102ddc0088f0a10a444@35.221.13.28:26656,25f5f65a09c56e9f1d2d90618aa70cd358aa68da@35.230.116.151:26656" ; s#^cors_allowed_origins.*#cors_allowed_origins = ["*"]#' $HOME/.heimdalld/config/config.toml

#####################################################################################
################################# HEIMDALLD SERVICE  ################################
#####################################################################################

echo -e "[Unit]
Description=Heimdalld
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
Restart=on-failure
RestartSec=5
TimeoutSec=900
User=$USER
Nice=0
LimitNOFILE=200000
WorkingDirectory=$HOME/.heimdalld/
ExecStart=$HOME/heimdall/build/heimdalld --home $HOME/.heimdalld/ start
KillSignal=SIGHUP

[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/heimdalld.service > /dev/null

#####################################################################################
################################# HEIMDALLR SERVICE  ################################
#####################################################################################

echo -e "[Unit]
Description=Heimdallr
After=network.target
StartLimitIntervalSec=60
StartLimitBurst=3

[Service]
Type=simple
Restart=on-failure
RestartSec=5
TimeoutSec=900
User=$USER
Nice=0
LimitNOFILE=200000
WorkingDirectory=$HOME/.heimdalld/
ExecStart=$HOME/heimdall/build/heimdalld --home $HOME/.heimdalld/ rest-server --chain-id=137
KillSignal=SIGHUP

[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/heimdallr.service > /dev/null

sudo systemctl daemon-reload

