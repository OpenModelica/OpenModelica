# Linux/WSL/OSX Instructions

## Table of content

- [1 Build dependencies](#1-build-dependencies)
  - [1.1 Debian/Ubuntu](#11-debianubuntu)
  - [1.2 Linux/BSD](#12-linuxbsd)
- [2 Compile OpenModelica](#2-compile-openmodelica)
  - [2.1 Configure and build](#21-configure-and-build)
  - [2.2 Install](#22-install)
- [3 Test Suite](#3-test-suite)
- [4 General Notes](#4-general-notes)

## 1. Build dependencies

Find out what Linux distribution you have via:

```bash
lsb_release --short --codename
```

Check if is supported here:
[Supported Distributions](http://build.openmodelica.org/apt/dists/)

If your distribution is supported go ahead and compile the code via the commands
below. If your distribution is not supported, it might still work if you use an
appropriate name instead of `lsb_release --short --codename` below.

If you are on a Windows Subsystem for Linux (WSL) we recommend using WSL2.
Otherwise just follow along the instructions below.

### 1.1 Debian/Ubuntu

Update your `sources.list`. You might want to substitute your release name for
the corresponding Debian or Ubuntu release if your OS is based on these and
there is no symbolic link in the repository yet.

```bash
sudo apt-get update
sudo apt-get install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

echo Linux name: `lsb_release --short --codename`
curl -fsSL http://build.openmodelica.org/apt/openmodelica.asc | sudo gpg --dearmor -o /usr/share/keyrings/openmodelica-keyring.gpg

echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt \
 $(lsb_release -cs) nightly" | sudo tee /etc/apt/sources.list.d/openmodelica.list > /dev/null
echo \
 "deb-src [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/openmodelica-keyring.gpg] https://build.openmodelica.org/apt \
 $(lsb_release -cs) nightly" | sudo tee -a /etc/apt/sources.list.d/openmodelica.list > /dev/null
```

To verify that the correct key is installed (optional):

```bash
gpg --show-keys /usr/share/keyrings/openmodelica-keyring.gpg
pub   rsa4096 2026-01-27 [SC]
      5DE86CC050F6623BBA7995B864CE41328E03B30A
uid                      OpenModelica Build System <build@openmodelica.org>
sub   rsa4096 2026-01-27 [E]
```

Then update and install OpenModelica build dependencies:

```bash
sudo apt-get update
sudo apt-get build-dep openmodelica
```

### 1.2 Linux/BSD

First you need to install the dependencies:

- [cmake](http://www.cmake.org) (>= 3.14), pkgconfig, g++, gfortran (pretty
  standard compilers)
- boost (optional, used with `-DOM_OMC_ENABLE_CPP_RUNTIME=ON`)
- [clang](http://clang.llvm.org/), clang++ (optional, but *highly recommended*;
  if you use gcc instead, use gcc 4.4 or 4.9+, not 4.5-4.8 as they are very
  slow)
- ccache (optional, but *highly recommended*, see
  [README.cmake.md](../README.cmake.md#2-ccache))
- hwloc (optional; queries the number of hardware CPU cores instead of logical
  CPU cores)
- Java JRE (JDK is optional; compiles the Java CORBA interface)
- Lapack/BLAS
- libhdf5 (optional part of the [MSL](https://github.com/modelica/Modelica)
  tables library supported by few other Modelica tools, so it does not do much)
- libexpat (it's actually included in the FMIL sources which are included... but
  we do not compile those and it's better to use the OS-provided dynamically
  linked version)
- omniORB or mico (optional; CORBA is used by OMOptim, OMShell, and OMPython)
- libcurl (libcurl4-gnutls-dev)
- ncurses, readline (optional, used by OMShell-terminal)
- OpenSceneGraph (optional, used by OMEdit)
- Qt6 or Qt5, Webkit, QtOpenGL (optional, used by OMEdit)

## 2 Compile OpenModelica

CMake is the only supported way to build OpenModelica.
[README.cmake.md](../README.cmake.md) documents the configuration options in
detail, the sections below are the short version.

### 2.1 Configure and build

```bash
# (Optional) Install ccache for faster re-compilation and flex for omc-diff
sudo apt-get install ccache flex
```

```bash
cd OpenModelica
# Configure and generate the build system in build_cmake/
cmake -S . -B build_cmake -DCMAKE_INSTALL_PREFIX=build
# Compile and install
cmake --build build_cmake --parallel <Nr. of cores> --target install
```

`omc` is then in `build/bin/omc`. If you do not pass `CMAKE_INSTALL_PREFIX`,
the default install directory is `build_cmake/install_cmake`.

Useful options (see [README.cmake.md](../README.cmake.md#4-configuration-options)
for the full list):

```bash
# Build the C++ simulation runtime as well
cmake -S . -B build_cmake -DOM_OMC_ENABLE_CPP_RUNTIME=ON
# Build only omc, without the Qt based GUI clients
cmake -S . -B build_cmake -DOM_ENABLE_GUI_CLIENTS=OFF
# No Fortran compiler available
cmake -S . -B build_cmake -DOM_OMC_ENABLE_FORTRAN=OFF -DOM_OMC_ENABLE_OPTIMIZATION=OFF -DOM_OMC_ENABLE_MOO=OFF
```

### 2.2 Install

To install OpenModelica for all users, configure with a system-wide prefix and
install with root privileges:

```bash
cd OpenModelica
cmake -S . -B build_cmake -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build_cmake --parallel <Nr. of cores>
sudo cmake --install build_cmake
```

## 3 Test suite

If you compiled the OpenModelica compiler successfully you can run the test
suite to check if everything is working. Some tests are a bit fragile and depend
on the OS and versions of used 3rd-party tools. So a few failing tests don't
have to be a major concern.

You'll need a few additional dependencies:

```bash
sudo apt-get install flex zip
```

Build the test suite dependencies (`omc-diff`, the reference files, the test
libraries and the FFI test library) with the `testsuite-depends` target:

```bash
cd OpenModelica
cmake --build build_cmake --target testsuite-depends --parallel <Nr. of cores>
```

`rtest` finds `omc` automatically if you installed to `build/`,
`build/install_cmake/` or `build_cmake/install_cmake/`. For any other
`CMAKE_INSTALL_PREFIX`, adjust the `$OPENMODELICAHOME` lookup in
`testsuite/rtest` (see
[README.cmake.md](../README.cmake.md#6-running-tests-rtest)).

Then run the test suite:

```bash
cd testsuite/partest
./runtests.pl
```

## 4 General Notes

If you run into problems open a
[discussion](https://github.com/OpenModelica/OpenModelica/discussions)
or subscribe to the
[OpenModelicaInterest list](https://www.openmodelica.org/index.php/home/mailing-list)
and then sent us an email at
[OpenModelicaInterest@ida.liu.se](mailto:OpenModelicaInterest@ida.liu.se).

--------------

Last updated 2026-08-21.
