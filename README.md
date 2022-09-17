# type2-runtime ![GitHub Actions](https://github.com/AppImage/type2-runtime/actions/workflows/build.yaml/badge.svg)

The runtime is the executable part of every AppImage. It mounts the payload via FUSE and executes the entrypoint.

This repository builds a statically linked runtime for type-2 AppImages in a [Alpine Linux](https://alpinelinux.org/) chroot with [musl libc](https://www.musl-libc.org/).

## Static AppImage runtime

__PLEASE NOTE: Do NOT add additional external dependencies or files. Everything shall be implemented in one file,  `runtime.c`.__

__PLEASE NOTE: Do NOT add a complicated "build system" (like autotools, CMake,...) other than the existing simple Makefile and bash.__

## Building locally

Binaries are provided on GitHub Releases. Should you prefer to build locally or on GitHub Codespaces, the following will build the contents of this repository in an Alpine container:

```
export ARCHITECTURE=x86_64
./chroot_build.sh
```

This whole process takes only a few seconds on GitHub Codespaces.
