FROM golang:1.10 AS builder

WORKDIR /go/src/github.com/syncthing/syncthing
COPY . .

ENV CGO_ENABLED=0
ENV BUILD_HOST=syncthing.net
ENV BUILD_USER=docker
RUN rm -f syncthing && go run build.go build syncthing

FROM alpine

EXPOSE 8384 22000 21027/udp

ENV SYNCDIR=/var/syncthing
VOLUME ["$SYNCDIR"]

RUN apk add --no-cache ca-certificates

COPY --from=builder /go/src/github.com/syncthing/syncthing/syncthing /bin/syncthing

RUN apk add --no-cache su-exec

ENV STNOUPGRADE=1
ENV PUID=1000
ENV PGID=1000
ENV UMASK=022

HEALTHCHECK --interval=1m --timeout=10s \
  CMD nc -z localhost 8384 || exit 1

ENTRYPOINT umask "$UMASK" \
    && chown $PUID:$PGID "$SYNCDIR" \
    && su-exec $PUID:$PGID /bin/syncthing -home /var/syncthing/config -gui-address 0.0.0.0:8384
