#! /bin/bash

set -euo pipefail

# use a temporary directory to download the files
tmpdir="$(mktemp -d)"

# clean it up whenever the script exits
cleanup() {
    echo "Cleaning up $tmpdir"
    rm -rf "$tmpdir"
}
trap cleanup EXIT

# store current file's path
# needed to determine the path of the patches
this_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"

cd "$tmpdir"

wget https://github.com/libfuse/libfuse/releases/download/fuse-3.17.2/fuse-3.17.2.tar.gz
echo "3d932431ad94e86179e5265cddde1d67aa3bb2fb09a5bd35c641f86f2b5ed06f  fuse-3.17.2.tar.gz" | sha256sum -c -
tar xf fuse-3.*.tar.gz
pushd fuse-3*/
patch -p1 < "$this_dir"/../../patches/libfuse/mount.c.diff
mkdir build
cd build
meson setup --prefix=/usr ..
meson configure -Dexamples=false --default-library static
ninja -v install
popd

# Minimize binary size
export CFLAGS="-ffunction-sections -fdata-sections -Os"

wget "https://github.com/vasi/squashfuse/releases/download/0.6.1/squashfuse-0.6.1.tar.gz"
echo "7b18a58c40a3161b5c329ae925b72336b5316941f906b446b8ed6c5a90989f8c  squashfuse-0.6.1.tar.gz" | sha256sum -c -
tar xf squashfuse-*.tar.gz
pushd squashfuse-*/
./configure LDFLAGS="-static"
make -j"$(nproc)"
make install
/usr/bin/install -c -m 644 ./*.h '/usr/local/include/squashfuse'
popd
