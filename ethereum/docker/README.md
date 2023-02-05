# Erigon on Docker

## Prerequisite
```
sudo apt-get install docker.io docker-compose curl
```
## Edit environment vars
```
cd rpc_emporium/ethereum/docker/

sudo nano .env
```
```
EMAIL=foo@foobar.com
DOMAIN=foobar.com
WHITELIST=11.111.111.111,22.222.222.222
```

## Edit Erigon Version (If needed)

```
sudo nano docker-compose.yml
```

```
  erigon-eth:
    container_name: erigon-eth
    build:
      args:
        ERIGON_VER: v2.37.0 # < change me.  match ver i.e. v2.37.0  *vvv*
      context: ./erigon-make
      dockerfile: Dockerfile
    image: erigon/erigon:v2.37.0 # < tag me. match ver i.e. v2.37.0 *^^^*
```

## Build & Run

```
docker-compose up -d
```

## Logs

```
docker logs erigon-eth -f
```

## Check RPC Status

```
curl --data '{"method":"eth_syncing","params":[],"id":1,"jsonrpc":"2.0"}' -H "Content-Type: application/json" -X POST http://{DOMAIN}/eth-archive
```



