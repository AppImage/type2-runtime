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
make -j"$(nproc)" runtime

file runtime

objcopy --only-keep-debug runtime runtime.debug

strip --strip-debug --strip-unneeded runtime

ls -lh runtime runtime.debug

# append architecture prefix
# since uname gives the kernel architecture but we need the userland architecture, we check /bin/bash
# all we have to do is convert uname's expected output to AppImage's semi-official suffix style
runtime="$(file -L /bin/bash)"

if [[ "$runtime" =~ 80386 ]]; then
    architecture=i686
elif [[ "$runtime" =~ i386 ]]; then
    architecture=i686
elif [[ "$runtime" =~ aarch64 ]]; then
    architecture=aarch64
elif [[ "$runtime" =~ EABI5 ]]; then
    architecture=armhf
elif [[ "$runtime" =~ x86-64 ]]; then
    architecture=x86_64
elif [[ "$runtime" =~ "64-bit .*, LoongArch" ]]; then
    architecture=loongarch64
else
    echo "Unsupported architecture: ${runtime#* }"
    exit 2
fi

mv runtime runtime-"$architecture"
mv runtime.debug runtime-"$architecture".debug

objcopy --add-gnu-debuglink runtime-"$architecture".debug runtime-"$architecture"

# "classic" magic bytes which cannot be embedded with compiler magic, always do AFTER strip
# needs to be done after calls to objcopy, strip etc.
# TODO: all these calls should be part of the Makefile
echo -ne 'AI\x02' | dd of=runtime-"$architecture" bs=1 count=3 seek=8 conv=notrunc

cp runtime-"$architecture" "$out_dir"/
cp runtime-"$architecture".debug "$out_dir"/

ls -al "$out_dir"
