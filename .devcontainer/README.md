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

- [build-deps-debian-12][1]: Debian 12 (Bookworm).
- [build-deps-debian-13][2]: Debian 13 (Trixie).
- [build-deps-ubuntu-22][3]: Ubuntu 22.04 (Jammy).
- [build-deps-ubuntu-24][4]: Ubuntu 24.04 (Noble).
- [build-deps-ubuntu-26][5]: Ubuntu 26.04 (Resolute).
- [build-deps-almalinux-10][6]: Enterprise Linux Almalinux 10.
- [build-deps-fedora-43][10]: Fedora 43.
- [build-deps-fedora-44][11]: Fedora 44.

There are two flavors:

- `debian-12`, `debian-13`, `ubuntu-22`, `almalinux-10`, `fedora-43` and
  `fedora-44` build a small wrapper `Dockerfile` that creates a non-root user
  matching your local user name and UID so files created in the container are
  owned by you.
- `ubuntu-24` and `ubuntu-26` use the base image directly and connect as the
  pre-existing `ubuntu` user.

## Usage in Visual Studio Code

Make sure you have Dev Containers extension
[ms-vscode-remote.remote-containers][7] and Docker installed and running.

Open command pallet (`Strg+Shift+P`) and run
`>Dev Containers: Open Folder in Container...`, select the OpenModelica
directory. Then select a devcontainer.json file to start.

## New Dev Container

Check directory [../.CI/][8] for more Dockerfiles used by Jenkins and construct
your own dev container in a similar way.

For more details check [containers.dev json reference][9].

## Adding VSCode Extensions

Use `customizations` in `devcontainer.json` to add more extensions to your dev
container.

## Caveats

The following only applies to the `Dockerfile`-based containers
(`debian-12`, `debian-13`, `ubuntu-22`, `almalinux-10`, `fedora-43`,
`fedora-44`):

- The images need an additional Dockerfile to add a non-root user with your
  user name and UID.
- Because on Windows and Unix the environment variable containing the user name
  are different and only one should be set both are added to devcontainer.json:
  If your user name isn't correct update it:

  ```diff
  -"${localEnv:USER}${localEnv:USERNAME}"
  +"username"
  ```

[1]: ./build-deps-debian-12/devcontainer.json
[2]: ./build-deps-debian-13/devcontainer.json
[3]: ./build-deps-ubuntu-22/devcontainer.json
[4]: ./build-deps-ubuntu-24/devcontainer.json
[5]: ./build-deps-ubuntu-26/devcontainer.json
[6]: ./build-deps-almalinux-10/devcontainer.json
[7]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[8]: ./../.CI/
[9]: https://containers.dev/implementors/json_reference/
[10]: ./build-deps-fedora-43/devcontainer.json
[11]: ./build-deps-fedora-44/devcontainer.json
