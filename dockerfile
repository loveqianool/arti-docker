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

COPY --from=builder /opt/arti/target/release/arti /usr/local/bin/arti

RUN groupadd -r arti && useradd -r -g arti arti

# 创建数据目录
RUN mkdir -p /var/lib/arti /home/arti/.config/arti && \
    chown -R arti:arti /var/lib/arti /home/arti

# 直接在 Dockerfile 中创建 entrypoint.sh
RUN cat > /entrypoint.sh << 'EOF'
#!/bin/sh
set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Starting with PUID=$PUID, PGID=$PGID"

# 修改用户 UID/GID
if [ "$(id -u arti)" != "$PUID" ] || [ "$(id -g arti)" != "$PGID" ]; then
    # 删除旧用户
    userdel arti 2>/dev/null || true
    groupdel arti 2>/dev/null || true
    
    # 创建新用户
    groupadd -g $PGID arti
    useradd -m -u $PUID -g arti -s /bin/sh arti
    
    # 修复权限
    chown -R arti:arti /var/lib/arti /home/arti
fi

# 切换到 arti 用户执行命令
exec su - arti -c "$*"
EOF

# 设置执行权限
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["arti", "proxy"]
