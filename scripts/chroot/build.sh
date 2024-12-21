#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine chroot environment"
	exit 1
fi

find /scripts

apk update
apk add alpine-sdk util-linux strace file autoconf automake libtool xz bash \
    eudev-dev gettext-dev linux-headers meson signify \
    zstd-dev zstd-static zlib-dev zlib-static clang

/scripts/common/install-dependencies.sh
/scripts/build-runtime.sh
