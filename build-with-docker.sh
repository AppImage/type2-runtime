#! /bin/bash

set -euo pipefail

orig_cwd="$(readlink -f .)"

if [[ "${ARCH:-}" == "" ]]; then
    echo "Usage: env ARCH=[...] $0"
    exit 2
fi

# guess architecture name compatible with Docker from $ARCH
case "${ARCH}" in
    x86_64)
        docker_arch=amd64
        docker_platform=linux/amd64
        ;;
    i686)
        docker_arch=i386
        docker_platform=linux/i386
        ;;
    armhf)
        docker_arch=arm32v7
        docker_platform=linux/arm32/v7
        ;;
    aarch64)
        docker_arch=arm64v8
        docker_platform=linux/arm64/v8
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 3
        ;;
esac

image_name="$docker_arch"/type2-runtime-build

# first, we need to build the image
# if nothing has changed, it'll run over this within a few seconds
this_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"
docker build --build-arg docker_arch="$docker_arch" --platform "$docker_platform" -t "$image_name" "$this_dir"

docker_run_args=()
[[ -t 0 ]] && docker_run_args+=("-t")

# next, build the binary in a container running this image
# we run the build as an unprivileged user to a) make sure that the build process does not require root permissions and b) make the resulting binary writable to the current user
set -x
docker run -u "$(id -u):$(id -g)" --platform "$docker_platform" --rm -i "${docker_run_args[@]}" -w /ws -v "$this_dir":/ws -v "$orig_cwd":/ws/out "$image_name" bash build-in-container.sh

# done!
# you should now have the binary in your current working directory
