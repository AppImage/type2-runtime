#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi

apk update
apk add alpine-sdk util-linux strace file autoconf automake libtool xz

# Build static libfuse3 with patch for https://github.com/AppImage/type2-runtime/issues/10
apk add eudev-dev gettext-dev linux-headers meson # From https://git.alpinelinux.org/aports/tree/main/fuse3/APKBUILD
wget -c -q "https://github.com/libfuse/libfuse/releases/download/fuse-3.15.0/fuse-3.15.0.tar.xz"
tar xf fuse-3.*.tar.xz
cd fuse-3.*/
wget "https://github.com/probonopd/libfuse/commit/bb5e23bb6d7ccb3a1f456fd35b716f6c3a9557c4.diff" # FIXME: Store diff locally
patch -p1 < bb5e23bb6d7ccb3a1f456fd35b716f6c3a9557c4.diff
mkdir build
cd build
meson setup ..
meson configure --default-library static
ninja install -v
cd ../../

# Build static squashfuse
apk add zstd-dev zlib-dev zlib-static # fuse3-dev fuse3-static fuse-static fuse-dev
find / -name "libzstd.*" 2>/dev/null || true
wget -c -q "https://github.com/vasi/squashfuse/archive/e51978c.tar.gz"
tar xf e51978c.tar.gz
cd squashfuse-*/
./autogen.sh
./configure --help
./configure CFLAGS=-no-pie LDFLAGS=-static
make -j"$(nproc)"
make install
/usr/bin/install -c -m 644 ./*.h '/usr/local/include/squashfuse' # ll.h
cd -

# Build static AppImage runtime
GIT_COMMIT="$(cat src/runtime/version)"
export GIT_COMMIT
cd src/runtime
make runtime-fuse3 -j"$(nproc)"
file runtime-fuse3
strip runtime-fuse3
ls -lh runtime-fuse3
echo -ne 'AI\x02' | dd of=runtime-fuse3 bs=1 count=3 seek=8 conv=notrunc # magic bytes, always do AFTER strip
cd -

mkdir -p out
cp src/runtime/runtime-fuse3 "out/runtime-fuse3-${ARCHITECTURE}"
