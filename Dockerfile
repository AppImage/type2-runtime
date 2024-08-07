ARG docker_arch
FROM ${docker_arch}/alpine:latest

# includes dependencies from https://git.alpinelinux.org/aports/tree/main/fuse3/APKBUILD
RUN apk add --no-cache \
    bash alpine-sdk util-linux strace file autoconf automake libtool xz \
    eudev-dev gettext-dev linux-headers meson \
    zstd-dev zstd-static zlib-dev zlib-static # fuse3-dev fuse3-static fuse-static fuse-dev

COPY scripts/install-dependencies.sh /tmp/scripts/install-dependencies.sh
COPY patches/ /tmp/patches/

WORKDIR /tmp
RUN bash scripts/install-dependencies.sh
