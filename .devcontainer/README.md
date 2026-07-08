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

- [build-deps-alpine-3.22][0]: Alpine 3.22.
- [build-deps-debian-12][1]: Debian 12 (Bookworm).
- [build-deps-debian-13][2]: Debian 13 (Trixie).
- [build-deps-ubuntu-22][3]: Ubuntu 22.04 (Jammy).
- [build-deps-ubuntu-24][4]: Ubuntu 24.04 (Noble).
- [build-deps-ubuntu-26][5]: Ubuntu 26.04 (Resolute).

There are two flavors:

- `alpine-3.22`, `debian-12`, `debian-13` and `ubuntu-22` build a small wrapper
  `Dockerfile` that creates a non-root user matching your local user name and
  UID so files created in the container are owned by you.
- `ubuntu-24` and `ubuntu-26` use the base image directly and connect as the
  pre-existing `ubuntu` user.

## Usage in Visual Studio Code

Make sure you have Dev Containers extension
[ms-vscode-remote.remote-containers][6] and Docker installed and running.

Open command pallet (`Strg+Shift+P`) and run
`>Dev Containers: Open Folder in Container...`, select the OpenModelica
directory. Then select a devcontainer.json file to start.

## New Dev Container

Check directory [../.CI/][7] for more Dockerfiles used by Jenkins and construct
your own dev container in a similar way.

For more details check [containers.dev json reference][8].

## Adding VSCode Extensions

Use `customizations` in `devcontainer.json` to add more extensions to your dev
container.

## Caveats

The following only applies to the `Dockerfile`-based containers
(`alpine-3.22`, `debian-12`, `debian-13`, `ubuntu-22`):

- The images need an additional Dockerfile to add a non-root user with your
  user name and UID.
- Because on Windows and Unix the environment variable containing the user name
  are different and only one should be set both are added to devcontainer.json:
  If your user name isn't correct update it:

  ```diff
  -"${localEnv:USER}${localEnv:USERNAME}"
  +"username"
  ```

[0]: ./build-deps-alpine-3.22/devcontainer.json
[1]: ./build-deps-debian-12/devcontainer.json
[2]: ./build-deps-debian-13/devcontainer.json
[3]: ./build-deps-ubuntu-22/devcontainer.json
[4]: ./build-deps-ubuntu-24/devcontainer.json
[5]: ./build-deps-ubuntu-26/devcontainer.json
[6]: https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers
[7]: ./../.CI/
[8]: https://containers.dev/implementors/json_reference/
