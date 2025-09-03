# syntax=docker/dockerfile:1

ARG VERSION_ARG="latest"

# ----- Stage 1: Build for amd64 -----
FROM scratch AS build-amd64
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
        netcat-openbsd \
        tini \
        python3 python3-minimal && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy runtime scripts/assets
COPY --chmod=755 ./src /run/
COPY --chmod=755 ./assets /run/assets

# Add helpers from Dockur project
ADD --chmod=755 https://raw.githubusercontent.com/christgau/wsdd/refs/tags/v0.9/src/wsdd.py /usr/sbin/wsdd
ADD --chmod=664 https://github.com/qemus/virtiso-whql/releases/download/v1.9.47-0/virtio-win-1.9.47.tar.xz /var/drivers.txz

# ----- Stage 2: Build for arm64 -----
FROM dockurr/windows-arm:${VERSION_ARG} AS build-arm64

# ----- Stage 3: Final runtime -----
FROM build-${TARGETARCH}

ARG VERSION_ARG="0.00"
RUN echo "$VERSION_ARG" > /run/version

# Ensure persistent storage path `/storage`
RUN mkdir -p /storage

# Ports
EXPOSE 3389 8006

# Default environment for Railway
ENV VERSION="11" \
    RAM_SIZE="32G" \
    CPU_CORES="12" \
    DISK_SIZE="500G" \
    STORAGE_PATH="/storage" \
    KVM="N" \
    USER_PORTS="3389 8006"

ENTRYPOINT ["/usr/bin/tini", "-s", "/run/entry.sh"]
