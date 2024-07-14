ARG docker_arch
FROM ${docker_arch}/alpine:latest

# includes dependencies from https://git.alpinelinux.org/aports/tree/main/fuse3/APKBUILD
RUN apk add --no-cache \
    bash alpine-sdk util-linux strace file autoconf automake libtool xz \
    eudev-dev gettext-dev linux-headers meson \
    zstd-dev zstd-static zlib-dev zlib-static # fuse3-dev fuse3-static fuse-static fuse-dev

COPY patches/ /tmp/patches/

WORKDIR /tmp

RUN wget https://github.com/libfuse/libfuse/releases/download/fuse-3.15.0/fuse-3.15.0.tar.xz && \
    echo "70589cfd5e1cff7ccd6ac91c86c01be340b227285c5e200baa284e401eea2ca0  fuse-3.15.0.tar.xz" | sha256sum -c && \
    tar xf fuse-3.*.tar.xz && \
    cd fuse-3*/ && \
    patch -p1 < /tmp/patches/libfuse/mount.c.diff && \
    mkdir build && \
    cd build && \
    meson setup --prefix=/usr .. && \
    meson configure --default-library static && \
    ninja -v install && \
    rm -r /tmp/fuse-*

# Minimize binary size
ENV CFLAGS="-ffunction-sections -fdata-sections -Os"

RUN wget "https://github.com/vasi/squashfuse/archive/e51978c.tar.gz" && \
    echo "f544029ad30d8fbde4e4540c574b8cdc6d38b94df025a98d8551a9441f07d341  e51978c.tar.gz" | sha256sum -c && \
    tar xf e51978c.tar.gz && \
    cd squashfuse-*/ && \
    ./autogen.sh && \
    ./configure CFLAGS="${CFLAGS} -no-pie" LDFLAGS=-static && \
    make -j"$(nproc)" && \
    make install && \
    /usr/bin/install -c -m 644 ./*.h '/usr/local/include/squashfuse' && \
    rm -r /tmp/e51978c* /tmp/squashfuse*
