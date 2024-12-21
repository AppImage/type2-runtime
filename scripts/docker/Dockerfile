FROM alpine:3.21

# includes dependencies from https://git.alpinelinux.org/aports/tree/main/fuse3/APKBUILD
RUN apk add --no-cache \
    bash alpine-sdk util-linux strace file autoconf automake libtool xz \
    eudev-dev gettext-dev linux-headers meson signify \
    zstd-dev zstd-static zlib-dev zlib-static clang

COPY scripts/common/install-dependencies.sh /tmp/scripts/common/.
COPY scripts/common/fuse-3.*.pub /tmp/scripts/common/.
COPY patches/ /tmp/patches/

WORKDIR /tmp
RUN bash scripts/common/install-dependencies.sh
