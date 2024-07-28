#! /bin/bash

set -ex

if [ -z "${ARCHITECTURE}" ]; then
    echo "Usage: env ARCHITECTURE=<arch> $0"
    exit 2
fi

# build in a temporary directory
# this makes sure that subsequent runs do not influence each other
# also makes cleaning up easier: just dump the entire directory
tempdir="$(mktemp -d)"

# need to memorize the repository root directory's path so that we can copy files from it
repo_root_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"/..

# cleanup takes care of unmounting and removing all downloaded files
cleanup() {
    sudo umount "$tempdir"/miniroot/{dev,proc,sys}
    sudo rm -rf "$tempdir"
}
trap cleanup EXIT

cd "$tempdir"

#############################################
# Download and extract minimal Alpine system
#############################################

wget "http://dl-cdn.alpinelinux.org/alpine/v3.17/releases/${ARCHITECTURE}/alpine-minirootfs-3.17.2-${ARCHITECTURE}.tar.gz"
mkdir -p ./miniroot
cd ./miniroot
sudo tar xf ../alpine-minirootfs-*-"${ARCHITECTURE}".tar.gz
cd -

#############################################
# Prepare chroot
#############################################

sudo cp -r "$repo_root_dir"/src miniroot/src
sudo cp -r "$repo_root_dir"/patches miniroot/patches

sudo mount -o bind /dev miniroot/dev
sudo mount -t proc none miniroot/proc
sudo mount -t sysfs none miniroot/sys
sudo cp -p /etc/resolv.conf miniroot/etc/

#############################################
# Run build.sh in chroot
#############################################

if [ "$ARCHITECTURE" = "x86" ] || [ "$ARCHITECTURE" = "x86_64" ]; then
    echo "Architecture is x86 or x86_64, hence not using qemu-arm-static"
    sudo cp "$repo_root_dir"/chroot/build.sh miniroot/build.sh && sudo chroot miniroot /bin/sh -ex /build.sh
elif [ "$ARCHITECTURE" = "aarch64" ] ; then
    echo "Architecture is aarch64, hence using qemu-aarch64-static"
    sudo cp "$(which qemu-aarch64-static)" miniroot/usr/bin
    sudo cp "$repo_root_dir"/chroot/build.sh miniroot/build.sh && sudo chroot miniroot qemu-aarch64-static /bin/sh -ex /build.sh
elif [ "$ARCHITECTURE" = "armhf" ] ; then
    echo "Architecture is armhf, hence using qemu-arm-static"
    sudo cp "$(which qemu-arm-static)" miniroot/usr/bin
    sudo cp "$repo_root_dir"/chroot/build.sh miniroot/build.sh && sudo chroot miniroot qemu-arm-static /bin/sh -ex /build.sh
else
    echo "Edit chroot_build.sh to support this architecture as well, it should be easy"
    exit 1
fi

#############################################
# Copy build artefacts out
#############################################

# Use the same architecture names as https://github.com/AppImage/AppImageKit/releases/
if [ "$ARCHITECTURE" = "x86" ] ; then ARCHITECTURE=i686 ; fi

cd "$repo_root_dir"
mkdir -p ./out/
sudo find "$tempdir"/miniroot/ -type f -executable -name 'runtime-fuse3' -exec cp {} "out/runtime-${ARCHITECTURE}" \;
