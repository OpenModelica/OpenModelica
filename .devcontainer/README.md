# Dev Container

The Visual Studio Dev Containers extension lets you use a Docker container as a
full-featured development environment.

With this setup it is easy to reproduce a similar state to what Jenkins is doing
in our continuous integration.

## Available Containers

We added three images that are used by the continuous integration used to
compile or test the pull requests on github.com/OpenModelica/OpenModelica.

- [build-deps](./build-deps/devcontainer.json): Default Ubuntu based build
  container to compile OpenModelica.
- [build-deps-debian-armhf](./build-deps-debian-armhf/devcontainer.json): Debian
  based container to compile for `aarch64-linux-gnu` and cross-compile for
  `arm-linux-gnueabihf`.

  > [!NOTE]
  > Running the container on a non-ARM CPU relies on QUEMU for emulation of an
  > ARM architecture and is very slow.

- [fmuchecker](./fmuchecker/devcontainer.json): Container with FMU checker to
  test generated FMUs.

  > [!IMPORTANT]
  > The Docker image is using a too old version of glibs to work with recent
  > versions of VS Code.

## Usage in Visual Studio Code

Make sure you have Dev Containers extension
[ms-vscode-remote.remote-containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
and Docker installed and running.

Open command pallet (`Strg+Shift+P`) and run
`>Dev Containers: Open Folder in Container...`, select the OpenModelica
directory. Then select a devcontainer.json file to start.

## New Dev Container

Check directory [../.CI/](./../.CI/) for more Dockerfiles used by Jenkins and
construct your own dev container in a similar way.

For more details check
[https://containers.dev/implementors/json_reference/](https://containers.dev/implementors/json_reference/).

## Adding VSCode Extensions

Use `customizations` in `devcontainer.json` to add more extensions to your dev
container.

## Caveats

- The images need an additional Dockerfile to add a non-root user with your
  user name and UID or rename an existing user.
- Because on Windows and Unix the environment variable containing the user name
  are different and only one should be set both are added to devcontainer.json:
  If your user name isn't correct update it:

  ```diff
  -"${localEnv:USER}${localEnv:USERNAME}"
  +"username"
  ```
