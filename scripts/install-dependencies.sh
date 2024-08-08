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

wget https://github.com/libfuse/libfuse/releases/download/fuse-3.15.0/fuse-3.15.0.tar.xz
echo "70589cfd5e1cff7ccd6ac91c86c01be340b227285c5e200baa284e401eea2ca0  fuse-3.15.0.tar.xz" | sha256sum -c -
tar xf fuse-3.*.tar.xz
pushd fuse-3*/
patch -p1 < "$this_dir"/../patches/libfuse/mount.c.diff
mkdir build
cd build
meson setup --prefix=/usr ..
meson configure --default-library static
ninja -v install
popd

# Minimize binary size
export CFLAGS="-ffunction-sections -fdata-sections -Os"

wget "https://github.com/vasi/squashfuse/archive/e51978c.tar.gz"
echo "f544029ad30d8fbde4e4540c574b8cdc6d38b94df025a98d8551a9441f07d341  e51978c.tar.gz" | sha256sum -c -
tar xf e51978c.tar.gz
pushd squashfuse-*/
./autogen.sh
./configure CFLAGS="${CFLAGS} -no-pie" LDFLAGS=-static
make -j"$(nproc)"
make install
/usr/bin/install -c -m 644 ./*.h '/usr/local/include/squashfuse'
popd
