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
COPY --chown=65532:65532 ./arti.toml /var/lib/tor/.config/arti/arti.toml

ENTRYPOINT [ "/usr/local/bin/arti" ]
CMD [ "help" ]
