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
        docker_platform=linux/arm/v7
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

load_arg=""
# Determine if '--load' is required
if docker buildx version > /dev/null 2>&1; then
    BUILDX_VERSION=$(docker buildx version | awk '{print $2}')
    # Define the version where --load became mandatory
    REQUIRED_VERSION="0.10.0"
    # Compare the current version with the required version
    if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$BUILDX_VERSION" | sort -V | head -n1)" = "$REQUIRED_VERSION" ]; then
        load_arg="--load"
    fi
fi

image_name="$docker_arch"/type2-runtime-build

# first, we need to build the image
# if nothing has changed, it'll run over this within a few seconds
repo_root_dir="$(readlink -f "$(dirname "${BASH_SOURCE[0]}")")"/../../
docker build --build-arg docker_arch="$docker_arch" --platform "$docker_platform" -t "$image_name" -f "$repo_root_dir"/scripts/docker/Dockerfile $load_arg "$repo_root_dir"

docker_run_args=()
[[ -t 0 ]] && docker_run_args+=("-t")

# split Docker args from command
while true; do
    # no more args left
    if [[ "${1:-}" == "" ]]; then
        break
    fi

    # consume --, the remaining args will be in the $@ array
    if [[ "$1" == "--" ]]; then
        shift
        break
    fi

    # append and consume Docker arg
    docker_run_args+=("$1")
    shift
done

# finally, we can run the build container
# we run the build as an unprivileged user to a) make sure that the build process does not require root permissions and b) make the resulting binary writable to the current user
exec docker run -u "$(id -u):$(id -g)" --platform "$docker_platform" --rm -i "${docker_run_args[@]}" -w /ws -v "$repo_root_dir":/ws -v "$orig_cwd":/ws/out "$image_name" "$@"
