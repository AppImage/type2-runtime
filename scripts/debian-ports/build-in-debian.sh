#! /bin/bash

# Builds the runtime in a Debian (ports) system, for the architectures that
# have no Alpine Linux, e.g. big endian ppc64: glibc instead of musl, gcc
# instead of clang, and no static PIE (glibc has none on every architecture).
# libfuse and squashfuse come from source as for the other architectures
# (scripts/common/install-dependencies.sh), zstd and zlib from Debian.
#
# (systemd-dev: the udev.pc that the build of libfuse reads, without systemd itself,
# whose maintainer scripts crash under QEMU)
#
# Usage (as root, in the repository, e.g. in a container):
#   bash scripts/debian-ports/build-in-debian.sh
# The runtime is written into out/.

set -euxo pipefail

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends \
    bash ca-certificates wget file patch xz-utils make gcc libc6-dev pkg-config \
    meson ninja-build autoconf automake libtool \
    libzstd-dev zlib1g-dev libmimalloc-dev systemd-dev

# meson installs libfuse into /usr/lib64, which pkg-config and gcc of Debian
# (multiarch: /usr/lib/<triplet>) do not search
export PKG_CONFIG_PATH=/usr/lib64/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}
export LIBRARY_PATH=/usr/lib64${LIBRARY_PATH:+:$LIBRARY_PATH}

bash scripts/common/install-dependencies.sh

# mimalloc only when Debian has its static library
make_args="CC=gcc STATIC_PIE="
if ! find /usr/lib -name libmimalloc.a | grep -q .; then
    make_args="$make_args MIMALLOC="
fi

RUNTIME_MAKE_ARGS="$make_args" bash scripts/build-runtime.sh
