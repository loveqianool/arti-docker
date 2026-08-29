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

RUN cd /opt && \
    git clone https://gitlab.torproject.org/tpo/core/arti.git && \
    cd /opt/arti && \
    cargo build --locked --release --package arti --features static

##################
# --- runner --- #
##################
FROM docker.io/alpine AS arti

COPY --from=builder /opt/arti/target/release/arti /usr/local/bin/arti

WORKDIR /app
ENV HOME=/app

ENTRYPOINT ["arti"]
CMD ["proxy"]
