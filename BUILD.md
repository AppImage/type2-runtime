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
> env ARCH=<arch> scripts/build-with-docker.sh
```

The resulting AppImages will end up in your current working directory.


### Interactive environment

You can spawn a development container locally using the following command:

```sh
> env ARCH=<arch> scripts/build-with-docker.sh
```


### Emulate foreign architectures

Docker supports using `binfmt_misc` and static QEMU builds to transparently run Docker images built for other architectures which the current CPU does not support. This way, one can, e.g., run a Docker container built for 64-bit ARM processors on a regular 64-bit AMD/Intel system.

To create an interactive container, that is, you can execute commands in there, you can use the following script:

```sh
> env ARCH=<arch> scripts/create-build-container.sh [docker args...]
```

This script first builds the Docker image (if necessary), then runs a container based on it.

The container mounts the repository's root directory in `/ws` so that you can run scripts, build the software etc.

You can optionally append Docker arguments. For instance, to run the container as a different user than `root` (which is the default), you can use the script as follows:

```sh
# bash
> env ARCH=<arch> scripts/create-build-container.sh -u "$(id -u):$(id -g)"

# fish
> env ARCH=<arch> scripts/create-build-container.sh -u (id -u):(id -g)
```

This is primarily useful if you don't intend to install packages interactively. It makes sure that the project can be built without root access. Packages can be installed by modifying the `install-dependencies.sh` script.

To specify commands that should be run, use the established `--` to distinguish these from Docker args:

```sh
# bash
> env ARCH=<arch> scripts/create-build-container.sh -u "$(id -u):$(id -g)" -- bash some-script.sh

# fish
> env ARCH=<arch> scripts/create-build-container.sh -u $(id -u):(id -g) -- bash some-script.sh
```
