#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi

apk update
apk add alpine-sdk util-linux strace file autoconf automake libtool

# Build static squashfuse
apk add fuse-dev fuse-static zstd-dev zlib-dev zlib-static # fuse3-static fuse3-dev
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
make runtime-fuse2 -j$(nproc)
file runtime-fuse2
strip runtime-fuse2
ls -lh runtime-fuse2
echo -ne 'AI\x02' | dd of=runtime-fuse2 bs=1 count=3 seek=8 conv=notrunc # magic bytes, always do AFTER strip
cd -

mkdir -p out
cp src/runtime/runtime-fuse2 out/runtime-fuse2-$ARCHITECTURE
