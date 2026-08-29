###################
# --- builder --- #
###################
FROM docker.io/rust:alpine AS builder

ARG TARGETPLATFORM
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
    case "${TARGETPLATFORM}" in \
        linux/amd64)  TARGET=x86_64-unknown-linux-musl ;; \
        linux/arm64)  TARGET=aarch64-unknown-linux-musl ;; \
        *) echo "unsupported ${TARGETPLATFORM}" ; exit 1 ;; \
    esac; \
    rustup target add "${TARGET}"

RUN cd /opt && \
    git clone https://gitlab.torproject.org/tpo/core/arti.git && \
    cd /opt/arti && \
    set -ex; \
    case "${TARGETPLATFORM}" in \
        linux/amd64)  TARGET=x86_64-unknown-linux-musl ;; \
        linux/arm64)  TARGET=aarch64-unknown-linux-musl ;; \
        *) echo "unsupported ${TARGETPLATFORM}" ; exit 1 ;; \
    esac; \
    cargo build --locked --release \
        --target "${TARGET}" \
        --package arti \
        --features static

##################
# debug runner (alpine, ash shell)
##################
FROM alpine AS arti-debug
COPY --from=builder /opt/arti/target/*-unknown-linux-musl/release/arti /usr/local/bin/arti
WORKDIR /app
ENV HOME=/app
ENTRYPOINT ["arti"]
CMD ["proxy"]

##################
# production runner (scratch, minimal no‑shell)
##################
FROM scratch AS arti
COPY --from=builder /opt/arti/target/*-unknown-linux-musl/release/arti /usr/local/bin/arti
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
WORKDIR /app
ENV HOME=/app
ENTRYPOINT ["arti"]
CMD ["proxy"]
