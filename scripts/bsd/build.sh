#!/bin/sh

# Entry point for a native FreeBSD build, the counterpart of
# scripts/docker/build-with-docker.sh and scripts/chroot/build.sh.
#
# Has to run as root, since it installs packages and the dependencies below
# /usr/local. Intended to be run in a throwaway VM.

set -eu

if [ "$(uname -s)" != FreeBSD ]; then
    echo "This script has to be run on FreeBSD" >&2
    exit 1
fi

this_dir="$(cd "$(dirname "$0")" && pwd)"

# binutils provides objcopy and the GNU ld the runtime has to be linked with;
# the rest is the toolchain needed to build libfuse and squashfuse
pkg install -y \
    autoconf \
    automake \
    binutils \
    gmake \
    liblz4 \
    libtool \
    lzo2 \
    meson \
    mimalloc \
    ninja \
    pkgconf \
    zstd

"$this_dir"/install-dependencies.sh
"$this_dir"/build-runtime.sh
