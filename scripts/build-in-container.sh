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
# since uname gives the kernel architecture but we need the userland architecture, we check /bin/bash
# all we have to do is convert uname's expected output to AppImage's semi-official suffix style
runtime=$(file -L /bin/bash)
if [[ $runtime =~ (64|32)-bit.*ELF ]]; then
    if [[ $runtime =~ i.86 ]]; then
        architecture=i686
    elif [[ $runtime =~ aarch64 ]]; then
        architecture=aarch64
    elif [[ $runtime =~ armv7l ]]; then
        architecture=armhf
    elif [[ $runtime =~ x86_64 ]]; then
        architecture=x86_64
    else
        echo "Unsupported architecture: ${runtime#* }"
        exit 2
    fi
else
    echo "Unsupported binary format: ${runtime#* }"
    exit 2
fi

mv runtime-fuse3 runtime-fuse3-"$architecture"
cp runtime-fuse3-"$architecture" "$out_dir"/

ls -al "$out_dir"

