#!/bin/sh

set -ex

if ! command -v apk; then
	echo "This script should be run in an Alpine container"
	exit 1
fi

cd "$(dirname "$0")"

apk update
apk add alpine-sdk util-linux strace file autoconf automake libtool

# Build static squashfuse
apk add zstd-dev zstd-static zlib-dev zlib-static
# We need to make sure only one version of fuse is installed so squashfuse sets the correct FUSE_USE_VERSION.
# See https://github.com/vasi/squashfuse/blob/d1d7dd/m4/squashfuse_fuse.m4#L146-L165
if [ "${FUSE_VERSION}" == "3" ]; then
	apk del fuse-dev fuse-static
	apk add fuse3-dev fuse3-static
else
	apk add fuse-dev fuse-static
	apk del fuse3-dev fuse3-static
fi
squashfuse_version="0.1.105"
wget -c -q "https://github.com/vasi/squashfuse/archive/refs/tags/${squashfuse_version}.tar.gz"
tar xf "${squashfuse_version}.tar.gz"
rm "${squashfuse_version}.tar.gz"
cd "squashfuse-${squashfuse_version}"
./autogen.sh
./configure --help
./configure CFLAGS=-no-pie LDFLAGS=-static
make -j$(nproc)
make install
/usr/bin/install -c -m 644 *.h '/usr/local/include/squashfuse' # ll.h
cd -
rm -rf "squashfuse-${squashfuse_version}"

# Build static AppImage runtime
export GIT_COMMIT=$(cat src/runtime/version)
cd src/runtime
runtime_name="runtime-fuse${FUSE_VERSION:-2}"
make clean
make "${runtime_name}" -j$(nproc)
file "${runtime_name}"
strip "${runtime_name}"
ls -lh "${runtime_name}"
echo -ne 'AI\x02' | dd of="${runtime_name}" bs=1 count=3 seek=8 conv=notrunc # magic bytes, always do AFTER strip
cd -

# Use the same architecture names as https://github.com/AppImage/AppImageKit/releases/
appimage_arch="$(apk --print-arch)"
appimage_arch="${appimage_arch/armv*/armhf}" # replaces "armv7l" with "armhf"
if [ "$appimage_arch" = "x86" ]; then appimage_arch=i686; fi

mkdir -p out
mv src/runtime/"${runtime_name}" out/"${runtime_name}"-"${appimage_arch}"
