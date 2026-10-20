#!/bin/sh

# Builds the runtime natively on FreeBSD.
#
# The counterpart of scripts/build-runtime.sh, which assumes a GNU userland:
# there is no nproc(1), the architecture cannot be read off /bin/bash (bash is
# not part of the base system), the Makefile needs GNU make, and objcopy comes
# from devel/binutils rather than the base system.

set -eu

# we'll copy the outcome into a subdirectory out in the current working directory
out_dir="$(pwd)"/out
mkdir -p "$out_dir"

: "${MAKE:=gmake}"
: "${OBJCOPY:=/usr/local/bin/objcopy}"
: "${STRIP:=/usr/local/bin/strip}"

njobs="$(sysctl -n hw.ncpu)"

cd src/runtime

$MAKE -j"$njobs" runtime

# the ELF OS/ABI ends up as ELFOSABI_FREEBSD on x86_64 and ELFOSABI_NONE on
# aarch64; both run, since what the kernel goes by is the FreeBSD ABI note,
# which ld.bfd emits either way
file runtime

$OBJCOPY --only-keep-debug runtime runtime.debug

$STRIP --strip-debug --strip-unneeded runtime

ls -lh runtime runtime.debug

# convert uname's output to AppImage's semi-official suffix style
# unlike the Linux build there is no 32-bit-userland-on-64-bit-kernel case to
# worry about here, so the kernel architecture is the userland architecture
machine="$(uname -m)"

case "$machine" in
    amd64|x86_64)
        architecture=x86_64
        ;;
    arm64|aarch64)
        architecture=aarch64
        ;;
    i386)
        architecture=i686
        ;;
    armv6|armv7)
        architecture=armhf
        ;;
    *)
        echo "Unsupported architecture: $machine"
        exit 2
        ;;
esac

# the OS is part of the name: a FreeBSD runtime is not interchangeable with the
# Linux runtime of the same architecture
os="$(uname -s | tr '[:upper:]' '[:lower:]')"
runtime="runtime-$os-$architecture"

mv runtime "$runtime"
mv runtime.debug "$runtime".debug

$OBJCOPY --add-gnu-debuglink "$runtime".debug "$runtime"

# "classic" magic bytes which cannot be embedded with compiler magic, always do AFTER strip
# needs to be done after calls to objcopy, strip etc.
printf 'AI\002' | dd of="$runtime" bs=1 count=3 seek=8 conv=notrunc

cp "$runtime" "$out_dir"/
cp "$runtime".debug "$out_dir"/

ls -al "$out_dir"
