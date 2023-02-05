FROM golang:1.19-alpine as builder
RUN apk add --no-cache make g++ gcc musl-dev linux-headers git curl jq
ARG ERIGON_VERSION=v2.37.0

WORKDIR /go/src/github.com/ledgerwatch
RUN git clone --recurse-submodules -j8 https://github.com/ledgerwatch/erigon.git

WORKDIR ./erigon
RUN git checkout ${ERIGON_VER} && make erigon

FROM alpine:3.13
RUN apk add --no-cache ca-certificates libstdc++ libgcc
COPY --from=builder /go/src/github.com/ledgerwatch/erigon/build/bin/erigon /usr/local/bin/
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod u+x /usr/local/bin/entrypoint.sh
EXPOSE 30303 8545 6060 6061
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
