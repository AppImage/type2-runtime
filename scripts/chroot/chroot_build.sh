#! /bin/sh

set -ex

ALPINE_RELEASE="3.21.0"

if [ -z "${ALPINE_ARCH}" ]; then
    echo "Usage: env ALPINE_ARCH=<arch> $0"
    echo "Example values: x86_64 x86 armhf aarch64"
    exit 2
fi

if [ "$(whoami)" = "root" ]; then
    alias sudo=
fi

# build in a temporary directory
# this makes sure that subsequent runs do not influence each other
# also makes cleaning up easier: just dump the entire directory
tempdir="$(mktemp -d)"

# need to memorize the repository root directory's path so that we can copy files from it
repo_root_dir=$(dirname "$(readlink -f "$0")")/../../

# cleanup takes care of unmounting and removing all downloaded files
cleanup() {
    for i in dev proc sys; do
        sudo umount "$tempdir"/miniroot/"$i"
    done
    sudo rm -rf "$tempdir"
}
trap cleanup EXIT

cd "$tempdir"

#############################################
# Download and extract minimal Alpine system
#############################################

mkdir "${tempdir}/.gpg"
chmod 700 "${tempdir}/.gpg"
gpg2 --homedir "${tempdir}/.gpg" --verbose --import "${repo_root_dir}/scripts/chroot/ncopa.asc"

wget "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_RELEASE%.*}/releases/${ALPINE_ARCH}/alpine-minirootfs-${ALPINE_RELEASE}-${ALPINE_ARCH}.tar.gz"
wget "https://dl-cdn.alpinelinux.org/alpine/v${ALPINE_RELEASE%.*}/releases/${ALPINE_ARCH}/alpine-minirootfs-${ALPINE_RELEASE}-${ALPINE_ARCH}.tar.gz.asc"
gpg2 --homedir "${tempdir}/.gpg" --verify "alpine-minirootfs-${ALPINE_RELEASE}-${ALPINE_ARCH}.tar.gz.asc"

mkdir -p ./miniroot
cd ./miniroot
sudo tar xf ../alpine-minirootfs-*-"${ALPINE_ARCH}".tar.gz
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

# copy build scripts so that they are available within the chroot environment
# build.sh combines existing scripts shared by all available build environments
sudo cp -R "$repo_root_dir"/scripts miniroot/scripts

if [ \
  "$(uname -m)" = "${ALPINE_ARCH}" \
  -o "${ALPINE_ARCH}" = "x86" -a "$(uname -m)" = "x86_64" \
  -o "${ALPINE_ARCH}" = "armhf" -a "$(uname -m)" = "aarch64" \
]; then
    sudo chroot miniroot /bin/sh -ex /scripts/chroot/build.sh
elif [ "${ALPINE_ARCH}" = "aarch64" ] ; then
    sudo cp "$(which qemu-aarch64-static)" miniroot/usr/bin
    sudo chroot miniroot qemu-aarch64-static /bin/sh -ex /scripts/chroot/build.sh
elif [ "${ALPINE_ARCH}" = "armhf" ] ; then
    sudo cp "$(which qemu-arm-static)" miniroot/usr/bin
    sudo chroot miniroot qemu-arm-static /bin/sh -ex /scripts/chroot/build.sh
else
    echo "Edit chroot_build.sh to support this architecture as well, it should be easy"
    exit 1
fi

#############################################
# Copy build artifacts out
#############################################

# Use the same architecture names as https://github.com/AppImage/AppImageKit/releases/
case "$ALPINE_ARCH" in
    x86)
        appimage_arch=i686
        ;;
    *)
        appimage_arch="$ALPINE_ARCH"
        ;;
esac

cd "$repo_root_dir"
mkdir -p ./out/
cp "${tempdir}/miniroot/out/runtime-${appimage_arch}" out/
cp "${tempdir}/miniroot/out/runtime-${appimage_arch}.debug" out/
