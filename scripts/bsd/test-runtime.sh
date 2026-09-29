#!/bin/sh

# Smoke test for a natively built FreeBSD runtime: assembles a minimal AppImage
# around it and runs it, which exercises the parts that differ from Linux --
# resolving the path of the running executable through the KERN_PROC_PATHNAME
# sysctl, and mounting the payload through mount_fusefs(8).
#
# Has to run as root: mounting requires either root or vfs.usermount=1.

set -eu

runtime="${1:-}"

if [ -z "$runtime" ]; then
    echo "usage: $0 <path to runtime>" >&2
    exit 1
fi

kldload -n fusefs

workdir="$(mktemp -d -t type2-runtime-test)"
appdir="$workdir"/AppDir
mkdir -p "$appdir"

cat > "$appdir"/AppRun <<'APPRUN'
#!/bin/sh
echo "AppRun running from $APPDIR"
echo "APPIMAGE is $APPIMAGE"
test -n "$APPIMAGE"
test -f "$APPIMAGE"
echo "smoke test ok"
APPRUN
chmod +x "$appdir"/AppRun

mksquashfs "$appdir" "$workdir"/payload.squashfs -root-owned -noappend

appimage="$workdir"/smoketest.AppImage
cat "$runtime" "$workdir"/payload.squashfs > "$appimage"
chmod +x "$appimage"

# --appimage-version and --appimage-help both write to stderr
echo "--- runtime reports its version ---"
"$appimage" --appimage-version 2>&1

# the path in the help output is the one the runtime resolved for itself, so
# this is what proves the KERN_PROC_PATHNAME lookup returned the right thing
echo "--- runtime prints its own path in the help output ---"
"$appimage" --appimage-help 2>&1 | grep -F "$appimage"

echo "--- mounting the payload and running AppRun ---"
"$appimage" | tee "$workdir"/output.txt

grep -q "smoke test ok" "$workdir"/output.txt

echo "--- extract-and-run fallback ---"
"$appimage" --appimage-extract-and-run | grep -q "smoke test ok"

echo "FreeBSD runtime smoke test passed"
