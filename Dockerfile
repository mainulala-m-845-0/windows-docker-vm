# syntax=docker/dockerfile:1

# ----- Build for amd64 -----
ARG VERSION_ARG="latest"
FROM scratch AS build-amd64

# QEMU for emulation
COPY --from=qemux/qemu:7.12 / /

ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

RUN set -eu && \
    apt-get update && \
    apt-get --no-install-recommends -y install \
        samba \
        wimtools \
        dos2unix \
        cabextract \
        libxml2-utils \
        libarchive-tools \
        netcat-openbsd && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=755 ./src /run/
COPY --chmod=755 ./assets /run/assets

ADD --chmod=755 \
    https://raw.githubusercontent.com/christgau/wsdd/refs/tags/v0.9/src/wsdd.py \
    /usr/sbin/wsdd

ADD --chmod=664 \
    https://github.com/qemus/virtiso-whql/releases/download/v1.9.47-0/virtio-win-1.9.47.tar.xz \
    /var/drivers.txz

# ----- Build for arm64 -----
FROM dockurr/windows-arm:${VERSION_ARG} AS build-arm64

# ----- Final build for the chosen architecture -----
FROM build-${TARGETARCH}

ARG VERSION_ARG="0.00"
RUN echo "$VERSION_ARG" > /run/version

# ❌ Removed VOLUME (Railway blocks this)
# 👉 Instead: mount Railway-managed volume at runtime:
#   railway volume create win-storage --mount /storage

# Networking
EXPOSE 3389 8006

# Runtime configuration
ENV VERSION="11"
ENV RAM_SIZE="32G"
ENV CPU_CORES="12"
ENV DISK_SIZE="500G"

# Flexible storage mount path
ENV STORAGE_PATH="/storage"

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
