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
patch -p1 < "$this_dir"/../../patches/libfuse/mount.c.diff
mkdir build
cd build
meson setup --prefix=/usr ..
meson configure --default-library static
ninja -v install
popd

# Minimize binary size
export CFLAGS="-ffunction-sections -fdata-sections -Os"

wget "https://github.com/vasi/squashfuse/archive/0.5.2.tar.gz"
echo "db0238c5981dabbd80ee09ae15387f390091668ca060a7bc38047912491443d3  0.5.2.tar.gz" | sha256sum -c -
tar xf 0.5.2.tar.gz
pushd squashfuse-*/
./autogen.sh
./configure LDFLAGS="-static"
make -j"$(nproc)"
make install
/usr/bin/install -c -m 644 ./*.h '/usr/local/include/squashfuse'
popd
