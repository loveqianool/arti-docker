###################
# --- builder --- #
###################
FROM docker.io/rust:alpine AS builder

RUN apk add --update git \
    musl-dev \
    pkgconfig \
    openssl-dev \
    perl \
    make

WORKDIR /opt
RUN git clone https://gitlab.torproject.org/tpo/core/arti.git
WORKDIR /opt/arti
RUN cargo build --locked --release --package arti

##################
# --- runner --- #
##################
FROM docker.io/alpine AS arti

RUN apk add --update --no-cache curl && \
    addgroup -g 65532 arti && \
    adduser --system --uid 65532 -G arti --home /var/lib/tor -s /bin/sh arti

COPY --from=builder /opt/arti/target/release/arti /usr/local/bin/arti

USER 65532
WORKDIR /var/lib/tor
RUN mkdir -p /var/lib/tor/.config/arti && \
    echo '[proxy]\n\
socks_listen = "0.0.0.0:9150"\n\
' \
> /var/lib/tor/.config/arti/arti.toml && \
    chown -R 65532:65532 /var/lib/tor

ENTRYPOINT [ "/usr/local/bin/arti" ]
CMD [ "help" ]
