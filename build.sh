#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi

apk update
apk add alpine-sdk util-linux strace file autoconf automake libtool

# Build static squashfuse
apk add fuse3-dev fuse3-static zstd-dev zlib-dev zlib-static # fuse-static fuse-dev
find / -name "libzstd.*" 2>/dev/null || true
wget -c -q "https://github.com/vasi/squashfuse/archive/e51978c.tar.gz"
tar xf e51978c.tar.gz
cd squashfuse-*/
./autogen.sh
./configure --help
./configure CFLAGS=-no-pie LDFLAGS=-static
make -j$(nproc)
make install
/usr/bin/install -c -m 644 *.h '/usr/local/include/squashfuse' # ll.h
cd -

# Build static AppImage runtime
export GIT_COMMIT=$(cat src/runtime/version)
cd src/runtime
make runtime-fuse3 -j$(nproc)
file runtime-fuse3
strip runtime-fuse3
ls -lh runtime-fuse3
echo -ne 'AI\x02' | dd of=runtime-fuse3 bs=1 count=3 seek=8 conv=notrunc # magic bytes, always do AFTER strip
cd -

mkdir -p out
cp src/runtime/runtime-fuse3 out/runtime-fuse3-$ARCHITECTURE
