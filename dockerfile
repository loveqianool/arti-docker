###################
# --- builder --- #
###################
FROM docker.io/rust:alpine AS builder

RUN apk add --update git \
    musl-dev \
    pkgconfig \
    openssl-dev \
    openssl-libs-static \
    perl \
    sqlite-dev \
    sqlite-static \
    make

WORKDIR /opt
RUN git clone https://gitlab.torproject.org/tpo/core/arti.git
WORKDIR /opt/arti
RUN cargo build --locked --release --package arti --features static

##################
# --- runner --- #
##################
FROM docker.io/alpine AS arti

RUN apk add --update --no-cache curl && \
    addgroup -g 65532 arti && \
    adduser --system --uid 65532 -G arti --home /var/lib/tor -s /bin/sh arti

COPY --from=builder /opt/arti/target/release/arti /usr/local/bin/arti

WORKDIR /var/lib/tor

ENTRYPOINT [ "/usr/local/bin/arti" ]
CMD [ "help" ]
