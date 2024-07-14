#! /bin/bash

set -x

set -euo pipefail

# we'll copy the outcome into a subdirectory out in the current working directory
out_dir="$(readlink -f "$(pwd)")"/out
mkdir -p "$out_dir"

# we create a temporary build directory
build_dir="$(mktemp -d -t type2-runtime-build-XXXXXX)"

# since the plain ol' Makefile doesn't support out-of-source builds at all, we need to copy all the files
cp -R src "$build_dir"/

pushd "$build_dir"

pushd src/runtime/
make -j"$(nproc)" runtime-fuse3

file runtime-fuse3

# optimize for size
# TODO: should be part of the Makefile
strip runtime-fuse3

# "classic" magic bytes which cannot be embedded with compiler magic, always do AFTER strip
# TODO: should be part of the Makefile
echo -ne 'AI\x02' | dd of=runtime-fuse3 bs=1 count=3 seek=8 conv=notrunc

ls -lh runtime-fuse3

# append architecture prefix
# since we expect to be built in a Dockerized environment, i.e., either run in a native environment or have it emulated transparently with QEMU, we can just use uname
# all we have to do is convert uname's expected output to AppImage's semi-official suffix style
case "$(uname -m)" in
    x86_64)
        architecture=x86_64
        ;;
    i386|i586|i686)
        architecture=i686
        ;;
    aarch64|arm64v8)
        architecture=aarch64
        ;;
    arm32v7|armv7l|armhf)
        architecture=armhf
        ;;
    *)
        echo "Unsupported architecture: $(uname -m)"
        exit 2
        ;;
esac

mv runtime-fuse3 runtime-fuse3-"$architecture"
cp runtime-fuse3-"$architecture" "$out_dir"/

ls -al "$out_dir"

