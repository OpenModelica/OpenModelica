# OpenModelica [![License: OSMC-PL](https://img.shields.io/badge/license-OSMC--PL-lightgrey.svg)](OSMC-License.txt)

[OpenModelica](https://openmodelica.org) is an open-source Modelica-based modeling and
simulation environment intended for industrial and academic usage.

## OpenModelica User's Guide

The [User's Guide](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/) is
automatically generated from the documentation repository.

## OpenModelica environment

The [OpenModelica Compiler](OMCompiler/) is the core of the OpenModelica project.
[OMEdit](OMEdit/README.md) is the graphical user interface on top of the compiler.
[OMSimulator](OMSimulator/README.md) is a capable FMI and SSP-based Co-Simulation environment,
available as a standalone version or integrated in OMEdit.
In addition there are interactive environments
[OMNotebook](OMNotebook/README.md), [OMPlot](OMPlot/README.md) and [OMShell](OMShell/README.md)
interaction with the OMCompiler as well as various other tools:
[OMOptim](OMOptim/README.md), [OMParser](OMParser/README.md),
[OMSense_Qt](OMSens_Qt/README.md).

## Working with the repository

OpenModelica.git is a superproject. Clone the project using one of:

```bash
# Faster pulling by using openmodelica.org read-only mirror (low latency in Europe; very important when updating all submodules)
# Replace the openmodelica.org pull URL with https://github.com/OpenModelica/OpenModelica.git if you want to pull directly from github
# The default choice is to push to your fork on github.com (SSH). Replace MY_FORK with OpenModelica to push directly to the OpenModelica repositories (if you have access)
MY_FORK=<MyGitHubUserName>
git clone --recurse-submodules https://openmodelica.org/git-readonly/OpenModelica.git
cd OpenModelica
git remote set-url --push origin git@github.com:$MY_FORK/OpenModelica.git
git submodule foreach --recursive 'git remote set-url --push origin `git config --get remote.origin.url | sed s,^.*/,git@github.com:'$MY_FORK'/,`'
```

If you are a developer and want to update your local git repository to the latest
developments use:

```bash
# After cloning
cd OpenModelica
git checkout master
git pull
git submodule update --force --init --recursive
```

In order to push to the repository, you will push to your own fork of OpenModelica.git,
etc. You will need to create a fork of each repository that you want to push to (by
clicking the Fork button in the GitHub web interface).

If you do not checkout the repositories for some GUI clients (such as OMOptim.git), these
directories are skipped during compilation.

To checkout a specific version of OpenModelica, say tag `v1.16.2` do:

```bash
git clone --recurse-submodules https://github.com/OpenModelica/OpenModelica.git
cd OpenModelica
git checkout v1.16.2
git submodule update --force --init --recursive
```

If you have issues building you can try to clean and reset the repository using:

```bash
git clean -fdx
git submodule foreach --recursive git clean -fdx
git reset --hard
git submodule foreach --recursive git reset --hard
git submodule update --init --recursive
```

To check your working copy status and the hashes of the submodules, use:

```bash
git status
git submodule status --recursive
```

### To checkout a minimal version of OpenModelica

```bash
git clone https://openmodelica.org/git-readonly/OpenModelica.git OpenModelica-minimal
cd OpenModelica-minimal
git submodule update --init --recursive libraries
```

## Build OpenModelica

OpenModelica is built with [CMake](https://cmake.org/); it is the only supported build
system.

```bash
cd OpenModelica
cmake -S . -B build_cmake
cmake --build build_cmake --parallel <Nr. of cores> --target install
./build_cmake/install_cmake/bin/omc --help
```

For dependencies, platform specifics and configuration options see:

* [Linux/WSL/OSX Instructions](OMCompiler/README.Linux.md)
* [Windows Instructions](OMCompiler/README.Windows.md)
* [CMake build instructions](README.cmake.md) (all platforms, configuration options)
* [CMake build instructions for MSVC](README.cmake.msvc.md)

We automatically generate nightly builds for
[Windows](https://openmodelica.org/download/download-windows/) and for various flavours of
[Linux](https://openmodelica.org/download/download-linux/). You can download and install
them directly if you just want to run the latest development version of OpenModelica without
the effort of compiling the sources yourself.

## How to contribute to the OpenModelica Compiler

The long-term development of OpenModelica is supported by a non-profit organization - the
[Open Source Modelica Consortium (OSMC)](https://openmodelica.org/home/consortium/).

See [CONTRIBUTING.md](CONTRIBUTING.md) on how to contribute to the development.
If you encounter any bugs, feel free to open a ticket about it.
For general questions regarding OpenModelica there is a
[discussions section](https://github.com/OpenModelica/OpenModelica/discussions) available.

## License

See [OSMC-License.txt](OSMC-License.txt).

## How to cite

See the [CITATIONS](CITATION.cff) file for information on how to cite OpenModelica in
any publications reporting work done using OpenModelica.
For a complete list of all publications related to OpenModelica see
[doc/bibliography/openmodelica.bib](./doc/bibliography/openmodelica.bib).

------------
Last updated: 2026-09-08
