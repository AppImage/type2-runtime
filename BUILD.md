# How to build the runtime

## Docker

As the runtime build requires a special environment with specific dependencies prebuilt and installed as static binaries, we provide a containerized build environment. We use Docker as a runtime for now.

Using containers provides the following advantages:

- Speed up local development by caching the built dependencies in the built image
- Automatically rebuild the image upon changes in the image's definition
- Isolate build environment from the host
- "Out-of-source" builds (in a naive way, we just copy the entire source code to a temporary build directory)

The build process has been automated completely. As a user, you just need to run the `build-with-docker.sh` script:

```sh
> env ARCH=<arch> ./build-with-docker.sh
```

The resulting AppImages will end up in your current working directory.
