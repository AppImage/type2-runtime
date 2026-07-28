#!/bin/sh

# Builds the static libfuse3 and squashfuse that the runtime is linked against.
#
# FreeBSD does package both of them (filesystems/fusefs-libs3 and
# filesystems/fusefs-squashfuse), but ships shared libraries only, while the
# runtime has to be statically linked, so they are built from source here.
#
# This is separate from scripts/common/install-dependencies.sh because almost
# every step differs: FreeBSD needs a much newer libfuse (3.17 and later carry
# the BSD fixes), the fusermount patch in patches/libfuse/ is Linux-only, the
# prefix is /usr/local rather than /usr, and there is no nproc(1).

set -eu

fuse_version=3.18.2
fuse_sha256=f01de85717e20adf5f98aff324acd85dd73d61a5ca3834d573dcf0bd6e54a298

squashfuse_version=0.5.2
squashfuse_sha256=db0238c5981dabbd80ee09ae15387f390091668ca060a7bc38047912491443d3

prefix=/usr/local
njobs="$(sysctl -n hw.ncpu)"

download() {
    if command -v fetch > /dev/null 2>&1; then
        fetch -o "$2" "$1"
    else
        curl -sSL -o "$2" "$1"
    fi
}

sha256_of() {
    if command -v sha256 > /dev/null 2>&1; then
        sha256 -q "$1"
    else
        sha256sum "$1" | cut -d' ' -f1
    fi
}

verify() {
    actual="$(sha256_of "$1")"

    if [ "$actual" != "$2" ]; then
        echo "checksum mismatch for $1: expected $2, got $actual" >&2
        exit 1
    fi
}

# the build trees are deliberately left behind: this runs in a throwaway build
# VM, and keeping them makes a failed build far easier to inspect
workdir="${WORKDIR:-$(mktemp -d -t type2-runtime-deps)}"
echo "Building dependencies in $workdir"
cd "$workdir"

# libfuse
download "https://github.com/libfuse/libfuse/releases/download/fuse-$fuse_version/fuse-$fuse_version.tar.gz" \
    "fuse-$fuse_version.tar.gz"
verify "fuse-$fuse_version.tar.gz" "$fuse_sha256"
tar xf "fuse-$fuse_version.tar.gz"

mkdir -p "fuse-$fuse_version"/build
cd "fuse-$fuse_version"/build
# only the library itself is needed; the helper programs are Linux-only
# (fusermount3 has no FreeBSD counterpart, FreeBSD mounts via mount_fusefs(8))
meson setup --prefix="$prefix" --default-library=static \
    -Dexamples=false -Dtests=false -Dutils=false ..
ninja -v install
cd "$workdir"

# squashfuse
# minimize binary size, same as the Linux build does
CFLAGS="-ffunction-sections -fdata-sections -Os"
export CFLAGS
PKG_CONFIG_PATH="$prefix/lib/pkgconfig:$prefix/libdata/pkgconfig"
export PKG_CONFIG_PATH

download "https://github.com/vasi/squashfuse/archive/$squashfuse_version.tar.gz" \
    "squashfuse-$squashfuse_version.tar.gz"
verify "squashfuse-$squashfuse_version.tar.gz" "$squashfuse_sha256"
tar xf "squashfuse-$squashfuse_version.tar.gz"

cd "squashfuse-$squashfuse_version"
./autogen.sh
./configure --prefix="$prefix" LDFLAGS="-static"
make -j"$njobs"
make install
# the runtime includes squashfuse internals (fuseprivate.h, ll.h) that are not
# part of the installed public headers
install -m 644 ./*.h "$prefix"/include/squashfuse
