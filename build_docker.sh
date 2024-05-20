#!/bin/bash

set -ex

if [[ "${ARCH:-}" == "" ]]; then
    echo "Usage: env ARCH=... bash $0"
    exit 1
fi

repo_root="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")"/.)"

case "$ARCH" in
    x86_64)
        image_prefix=amd64/alpine
        platform=linux/amd64
        ;;
    i686)
        image_prefix=i386/alpine
        platform=linux/i386
        ;;
    armhf)
        image_prefix=arm32v7/alpine
        platform=linux/arm/v7
        ;;
    aarch64)
        image_prefix=arm64v8/alpine
        platform=linux/arm64/v8
        ;;
    loong64)
        image_prefix=lcr.loongnix.cn/library/alpine # official unsatble
        platform=linux/loong64
        ;;
    *)
        echo "unknown architecture: $ARCH"
        exit 2
        ;;
esac

uid="$(id -u)"
docker run \
    --rm \
    -i \
    -e ARCH \
    -e GITHUB_ACTIONS \
    -e GITHUB_RUN_NUMBER \
    -e ARCHITECTURE="loong64" \
    -e OUT_UID="$uid" \
    -v "$repo_root":/source \
    -v "$PWD":/out \
    -w /out \
    "$image_prefix:3.19" \
    sh <<\EOF
/source/build.sh
chown "$OUT_UID" out
chown "$OUT_UID" out/*
EOF

mv out/runtime-fuse3-loong64 out/runtime-loong64