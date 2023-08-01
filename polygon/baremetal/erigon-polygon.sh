
#!/bin/bash

#versions
erigon=v2.35.2

#dependencies
sudo apt install -y build-essential bsdmainutils aria2 pigz screen clang cmake curl httpie jq nano wget git

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
User=root
Nice=0
LimitNOFILE=200000
WorkingDirectory=/root/.local/share/erigon/
ExecStart=/root/erigon/build/bin/erigon \\
        --chain=bor-mainnet \\
        --datadir=/root/.local/share/erigon/datadir \\
        --ethash.dagdir=/root/.local/share/erigon/datadir/ethash \\
        --snapshots=false \\
        --snap.stop \\
        --bor.heimdall=http://localhost:1317 \\
        --http --http.addr=0.0.0.0 --http.port=9656 \\
        --http.compression --http.vhosts=* --http.corsdomain=* \\
        --http.api=eth,debug,net,trace,web3,erigon,bor \\
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
WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/erigon.service > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable erigon
sudo systemctl start erigon
