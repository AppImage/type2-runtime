# type2-runtime ![GitHub Actions](https://github.com/AppImage/type2-runtime/actions/workflows/build.yaml/badge.svg)

The runtime is the executable part of every AppImage. It mounts the payload via FUSE and executes the entrypoint.

This repository builds a statically linked runtime for type-2 AppImages in a [Alpine Linux](https://alpinelinux.org/) chroot with [musl libc](https://www.musl-libc.org/).

Since the runtime is linked statically, libfuse2 is no longer required on the target system.

## Notes for users

As an AppImage user, you do not need this repository, as the AppImage runtime is embedded into every AppImage.

## Notes for developers

__Please note:__ This repository is meant to be extremely simple.

* Do NOT add additional external dependencies or files. Everything shall be implemented in one file. `runtime.c`  
* Do NOT add a complicated "build system" (like autotools, CMake,...) other than the existing simple Makefile and bash

Binaries are provided on GitHub Releases. Should you need to build the runtime locally or on GitHub Codespaces, the following will build the contents of this repository in an Alpine container:

```
export ALPINE_ARCH=x86_64
./chroot/chroot_build.sh # Or execute the steps in it manually
```

This whole process takes only a few seconds, e.g., on GitHub Codespaces.

## Signing

Release builds are signed automatically using GnuPG. The corresponding public key can be found in the file `signing-pubkey.asc`.
