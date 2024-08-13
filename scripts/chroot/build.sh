#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine chroot environment"
	exit 1
fi

find /scripts

apk update
apk add alpine-sdk util-linux strace file autoconf automake libtool xz bash \
    eudev-dev gettext-dev linux-headers meson \
    zstd-dev zlib-dev zlib-static # fuse3-dev fuse3-static fuse-static fuse-dev

/scripts/common/install-dependencies.sh
/scripts/build-runtime.sh
