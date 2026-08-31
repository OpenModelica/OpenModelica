# Dev Container

The Visual Studio Dev Containers extension lets you use a Docker container as a
full-featured development environment.

With this setup it is easy to reproduce a similar state to what Jenkins is doing
in our continuous integration.

## Available Containers

We provide `build-deps` dev containers for the Linux distributions used by the
continuous integration that compiles and tests the pull requests on
github.com/OpenModelica/OpenModelica. Each one is based on the matching
`docker.openmodelica.org/build-deps:*-debug` image and contains all
dependencies needed to compile OpenModelica.

- [build-deps-alpine-3.22][alpine-3.22-dev]: Alpine 3.22.
- [build-deps-debian-12][debian-bookworm-dev]: Debian 12 (Bookworm).
- [build-deps-debian-13][debian-trixie-dev]: Debian 13 (Trixie).
- [build-deps-ubuntu-22][ubuntu-jammy-dev]: Ubuntu 22.04 (Jammy).
- [build-deps-ubuntu-24][ubuntu-noble-dev]: Ubuntu 24.04 (Noble).
- [build-deps-ubuntu-26][ubuntu-resolute-dev]: Ubuntu 26.04 (Resolute).
- [build-deps-almalinux-10][el-10-dev]: Enterprise Linux Almalinux 10.
- [build-deps-fedora-43][fedora-43-dev]: Fedora 43.
- [build-deps-fedora-44][fedora-44-dev]: Fedora 44.
- [build-deps-ubuntu-26-rust][ubuntu-resolute-rust-dev]: Ubuntu 26.04 with the
  Rust/clang/wasm toolchain, reproducing the `cmake-rust-clang` CI stage.

There are two flavors:

- `alpine-3.22`, `debian-12`, `debian-13`, `ubuntu-22`, `almalinux-10`,
  `fedora-43`, `fedora-44` and `ubuntu-26-rust` build a small wrapper
  `Dockerfile` that creates a non-root user matching your local user name and
  UID so files created in the container are owned by you.
- `ubuntu-24` and `ubuntu-26` use the base image directly and connect as the
  pre-existing `ubuntu` user.

## Usage in Visual Studio Code

Make sure you have Dev Containers extension
[ms-vscode-remote.remote-containers][remote-containers-url] and Docker installed
and running.

Open command pallet (`Strg+Shift+P`) and run
`>Dev Containers: Open Folder in Container...`, select the OpenModelica
directory. Then select a devcontainer.json file to start.

## Reproducing the cmake-rust-clang CI stage

`build-deps-ubuntu-26-rust` pins the same image the `cmake-rust-clang` stage in
[../Jenkinsfile][jenkinsfile] uses and mounts the same cargo/sccache/omlibrary
cache volumes. Inside the container run:

```bash
.devcontainer/build-deps-ubuntu-26-rust/build-rust-clang.sh
```

which performs the same configure and the same `install`, `rust_wasm_runtime`
and `testsuite-depends` builds as `common.buildRustOMC()` in
[../.CI/common.groovy][common-groovy]. Pass `--clean` to also run the
`git clean -ffdx` that the CI agent does first — that deletes every untracked
and ignored file in the worktree and all submodules, so it is opt-in.

Two deliberate differences from CI:

- **sccache backend.** CI shares an S3 bucket behind a Jenkins credential. The
  container keeps the same compiler-launcher wiring but caches to disk in the
  mounted volume instead.
- **`CARGO_HOME`.** The image ships `CARGO_HOME=/opt/rust/cargo`, which is
  root-owned, and cargo has to write it. The `Dockerfile` moves `CARGO_HOME` to
  `~/.cargo` instead of taking ownership of `/opt/rust`, which would copy the
  whole Rust toolchain into another image layer. `RUSTUP_HOME` is untouched;
  running `rustc`/`cargo` only reads it.

## New Dev Container

Check directory [../.CI/][ci-dir] for more Dockerfiles used by Jenkins and
construct your own dev container in a similar way.

For more details check [containers.dev json reference][dev-json-ref-url].

## Adding VSCode Extensions

Use `customizations` in `devcontainer.json` to add more extensions to your dev
container.

## Caveats

The following only applies to the `Dockerfile`-based containers
(`alpine-3.22`, `debian-12`, `debian-13`, `ubuntu-22`, `almalinux-10`,
`fedora-43`, `fedora-44`):

- The images need an additional Dockerfile to add a non-root user with your
  user name and UID.
- Because on Windows and Unix the environment variable containing the user name
  are different and only one should be set both are added to devcontainer.json:
  If your user name isn't correct update it:

  ```diff
  -"${localEnv:USER}${localEnv:USERNAME}"
  +"username"
  ```

[alpine-3.22-dev]: ./build-deps-alpine-3.22/devcontainer.json
[debian-bookworm-dev]: ./build-deps-debian-12/devcontainer.json
[debian-trixie-dev]: ./build-deps-debian-13/devcontainer.json
[ubuntu-jammy-dev]: ./build-deps-ubuntu-22/devcontainer.json
[ubuntu-noble-dev]: ./build-deps-ubuntu-24/devcontainer.json
[ubuntu-resolute-dev]: ./build-deps-ubuntu-26/devcontainer.json
[ubuntu-resolute-rust-dev]: ./build-deps-ubuntu-26-rust/devcontainer.json
[el-10-dev]: ./build-deps-almalinux-10/devcontainer.json
[fedora-43-dev]: ./build-deps-fedora-43/devcontainer.json
[fedora-44-dev]: ./build-deps-fedora-44/devcontainer.json
[remote-containers-url]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[ci-dir]: ./../.CI/
[jenkinsfile]: ./../Jenkinsfile
[common-groovy]: ./../.CI/common.groovy
[dev-json-ref-url]: https://containers.dev/implementors/json_reference/
