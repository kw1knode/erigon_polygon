#!/bin/bash

# Exit script if any command fails
set -e

# Check if user has sudo permissions
if [[ $(id -u) -ne 0 ]]; then
    echo "You need to have root privileges to run this script"
    exit 1
fi

cd ~

#versions
gover=1.19.4
heimdall=v0.3.0

#dependencies
sudo apt install -y build-essential bsdmainutils aria2 pigz screen clang cmake curl httpie jq nano wget git

#golang
cd $HOME
wget "https://golang.org/dl/go$gover.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$gover.linux-amd64.tar.gz"
rm "go$gover.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.profile
source $HOME/.profile

#heimdall
git clone -b $heimdall https://github.com/maticnetwork/heimdall
cd heimdall
make build network=mainnet
$HOME/heimdall/build/heimdalld init 
cd $HOME/.heimdalld
wget -O $HOME/.heimdalld/config/genesis.json https://raw.githubusercontent.com/maticnetwork/launch/master/mainnet-v1/without-sentry/heimdall/config/genesis.json
sed -i '/^seeds/c\seeds = "f4f605d60b8ffaaf15240564e58a81103510631c@159.203.9.164:26656,4fb1bc820088764a564d4f66bba1963d47d82329@44.232.55.71:26656,2eadba4be3ce47ac8db0a3538cb923b57b41c927@35.199.4.13:26656,3b23b20017a6f348d329c102ddc0088f0a10a444@35.221.13.28:26656,25f5f65a09c56e9f1d2d90618aa70cd358aa68da@35.230.116.151:26656" ; s#^cors_allowed_origins.*#cors_allowed_origins = ["*"]#' $HOME/.heimdalld/config/config.toml

#heimdalld service
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

#heimdallr service
echo "[Unit]
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
sudo systemctl enable heimdalld
sudo systemctl enable heimdallr
sudo systemctl start heimdalld
sudo systemctl start heimdallr
