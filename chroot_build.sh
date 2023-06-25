#!/bin/sh

set -ex

#############################################
# Download and extract minimal Alpine system
#############################################

wget http://dl-cdn.alpinelinux.org/alpine/v3.17/releases/$ARCHITECTURE/alpine-minirootfs-3.17.2-$ARCHITECTURE.tar.gz
sudo rm -rf ./miniroot  true # Clean up from previous runs
mkdir -p ./miniroot
cd ./miniroot
sudo tar xf ../alpine-minirootfs-*-$ARCHITECTURE.tar.gz
cd -

#############################################
# Prepare chroot
#############################################

sudo cp -r ./src miniroot/src

sudo mount -o bind /dev miniroot/dev
sudo mount -t proc none miniroot/proc
sudo mount -t sysfs none miniroot/sys
sudo cp -p /etc/resolv.conf miniroot/etc/

#############################################
# Run build.sh in chroot
#############################################

if [ "$ARCHITECTURE" = "x86" ] || [ "$ARCHITECTURE" = "x86_64" ]; then
    echo "Architecture is x86 or x86_64, hence not using qemu-arm-static"
    sudo chroot miniroot /bin/sh -ex build.sh
else
    echo "Architecture is something else, hence using qemu-arm-static"
    sudo apt-get -y install qemu-user-static
    sudo cp $(which qemu-arm-static) miniroot/usr/bin
    # sudo chroot miniroot qemu-arm-static /bin/sh -ex <build.sh
    sudo chroot miniroot qemu-arm-static /bin/sh -ex build.sh
fi

#############################################
# Clean up chroot
#############################################

sudo umount miniroot/proc miniroot/sys miniroot/dev

#############################################
# Copy build artefacts out
#############################################

# Use the same architecture names as https://github.com/AppImage/AppImageKit/releases/
if [ "$ARCHITECTURE" = "x86" ] ; then ARCHITECTURE=i686 ; fi

mkdir out/
sudo find miniroot/ -type f -executable -name 'runtime-fuse3' -exec cp {} out/runtime-fuse3-$ARCHITECTURE \;
sudo rm -rf miniroot/
