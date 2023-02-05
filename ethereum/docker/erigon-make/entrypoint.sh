#!/bin/sh

set -e

ERIGON_HOME=/datadir

exec erigon \
      --chain=mainnet \
      --datadir=${ERIGON_HOME} \
      --rpc.gascap=50000000 \
      --http \
      --rpc.batch.concurrency=100 \
      --state.cache=2000000 \
      --http.addr="0.0.0.0" \
      --http.port="8545" \
      --http.api="eth,erigon,web3,net,debug,trace,txpool" \
      --http.vhosts="*" \
      --http.corsdomain="*" \
      --ws --ws.compression \
      --port=30303 \
      --torrent.upload.rate="90m" --torrent.download.rate="90m" \
      --metrics --metrics.addr=0.0.0.0 --metrics.port=6060 \
      --pprof --pprof.addr=0.0.0.0 --pprof.port=6061
