![alt text](https://upload.wikimedia.org/wikipedia/commons/2/24/Polygon_blockchain_logo.png)

## Edit Version Variables (If needed)
```bash
# erigon
erigon=v2.35.x
#go
gover=1.19.x
#heimdall
heimdall=v0.3.x
```


## Install Heimdall ***first*** & Sync
```
cd polygon

chmod +x heimdall.sh

./heimdall.sh
```
## Check Sync Status
```
curl http://localhost:26657/status
```
```bash
"network": should be "heimdall-137" and "catching_up": false
```

## Install Erigon
```
cd polygon

chmod +x erigon-polygon.sh

./erigon-polygon
```

## Check Logs
```bash
# Erigon
sudo journalctl -fu erigon
```
```bash
# Heimdall
sudo journalctl -fu heimdalld
sudo journalctl -fu heimdallr
```
