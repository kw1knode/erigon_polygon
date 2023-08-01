FROM golang:1.19-alpine as builder
RUN apk add --no-cache make g++ gcc musl-dev linux-headers git
ARG ERIGON_VERSION=v2.48.1

RUN git clone --branch stable --single-branch https://github.com/ledgerwatch/erigon.git

WORKDIR ./erigon

RUN git checkout ${ERIGON_VERSION}

RUN make erigon

FROM alpine:latest

RUN apk add --no-cache ca-certificates curl jq libstdc++ libgcc
COPY --from=builder /go/erigon/build/bin/erigon /usr/local/bin/

ENV HEIMDALLD=http://heimdalld:26657
ENV HEIMDALLR=https://heimdallr:1317

EXPOSE 27113
EXPOSE 8545
EXPOSE 6060
EXPOSE 6061

COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod u+x /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]