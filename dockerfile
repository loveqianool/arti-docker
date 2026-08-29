###################
# --- builder --- #
###################
FROM docker.io/rust:alpine AS builder

RUN apk add --update git \
    musl-dev \
    musl-tools \
    pkgconfig \
    openssl-dev \
    openssl-libs-static \
    perl \
    sqlite-dev \
    sqlite-static \
    make

RUN set -ex; \
    TARGET=""; \
    if [ "$(uname -m)" = "x86_64" ]; then TARGET=x86_64-unknown-linux-musl; fi; \
    if [ "$(uname -m)" = "aarch64" ]; then TARGET=aarch64-unknown-linux-musl; fi; \
    rustup target add "${TARGET}"

RUN cd /opt && \
    git clone https://gitlab.torproject.org/tpo/core/arti.git && \
    cd /opt/arti && \
    set -ex; \
    TARGET=""; \
    if [ "$(uname -m)" = "x86_64" ]; then TARGET=x86_64-unknown-linux-musl; fi; \
    if [ "$(uname -m)" = "aarch64" ]; then TARGET=aarch64-unknown-linux-musl; fi; \
    cargo build --locked --release \
        --target "${TARGET}" \
        --package arti \
        --features static

##################
# debug runner (alpine, with ash shell)
##################
FROM alpine AS arti-debug
COPY --from=builder /opt/arti/target/*-unknown-linux-musl/release/arti /usr/local/bin/arti
WORKDIR /app
ENV HOME=/app
ENTRYPOINT ["arti"]
CMD ["proxy"]

##################
# production runner (scratch, minimal, no shell)
##################
FROM scratch AS arti
COPY --from=builder /opt/arti/target/*-unknown-linux-musl/release/arti /usr/local/bin/arti
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
WORKDIR /app
ENV HOME=/app
ENTRYPOINT ["arti"]
CMD ["proxy"]
