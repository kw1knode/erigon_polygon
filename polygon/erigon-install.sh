
#!/bin/bash

#versions
gover=1.19.4
erigon=v2.35.2

#dependencies
sudo apt install -y build-essential bsdmainutils aria2 golang pigz screen clang cmake curl httpie jq nano wget git

#golang
cd $HOME
wget "https://golang.org/dl/go$gover.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$gover.linux-amd64.tar.gz"
rm "go$gover.linux-amd64.tar.gz"
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.profile
source $HOME/.profile

#erigon
cd ~
curl -LO https://github.com/ledgerwatch/erigon/archive/refs/tags/$erigon.tar.gz
tar xvf $erigon.tar.gz
cd erigon-$erigon
make erigon
cd ~
sudo cp -a erigon-$erigon /usr/local/bin/erigon
rm $erigon.tar.gz
rm -r erigon-$erigon
sudo useradd --no-create-home --shell /bin/false erigon
sudo mkdir -p /var/lib/erigon
sudo chown -R erigon:erigon /var/lib/erigon

#erigon service
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
User=erigon
Nice=0
LimitNOFILE=200000
ExecStart=/usr/local/bin/erigon/build/bin/erigon \\
  --chain="bor-mainnet" \\
  --datadir="/var/lib/erigon" \\
  --ethash.dagdir="/var/lib/erigon/ethash" \\
  --snapshots="true" \\
  --bor.heimdall="http://localhost:1317" \\
  --http --http.addr="0.0.0.0" \\
  --http.port="8545" \\
  --http.compression \\ 
  --http.vhosts="*" \\
  --http.corsdomain="*" \\
  --http.api="eth,debug,net,trace,web3,erigon,bor" \\
  --ws --ws.compression \\
  --rpc.gascap="300000000" \\
  --metrics \\
  --metrics.addr="0.0.0.0" \\
  --rpc.returndata.limit="500000" \\
  --metrics.port="9595"
[Install]
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/erigon.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable erigon
sudo systemctl start erigon
