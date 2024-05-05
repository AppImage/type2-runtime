#! /bin/bash

set -euo pipefail

if [[ "${SIGNING_KEY:-}" == "" ]] || [[ ! -f "${1:-}" ]]; then
    echo "Usage: env SIGNING_KEY=... $0 runtime-<arch>"
    exit 2
fi

tmpdir="$(mktemp -d)"
chmod 0700 "$tmpdir"

cleanup() {
    if [[ -d "$tmpdir" ]]; then
        rm -rf "$tmpdir"
    fi
}

trap cleanup EXIT

export GNUPGHOME="$tmpdir"

echo "=== importing key ==="
echo -e "$SIGNING_KEY" | gpg2 --verbose --batch --import

echo
echo "=== listing available secret keys ==="
gpg2 -K

echo
echo "=== signing $1 ==="
gpg2 --verbose --batch --sign --detach -o "$1".sig "$1"

echo
echo "=== test-verifying signature ==="
gpg2 --verbose --batch --verify "$1".sig "$1"
