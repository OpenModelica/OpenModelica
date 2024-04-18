# Linux/WSL/OSX Instructions

## Table of content

- [1 Build dependencies](#1-build-dependencies)
  - [1.1 Debian/Ubuntu](#11-debianubuntu)
  - [1.2 Linux/BSD](#12-linuxbsd)
- [2 Compile OpenModelica](#2-compile-openmodelica)
  - [2.1 CMake build](#21-cmake-build)
  - [2.2 Make build](#22-make-build)
  - [2.3 CORBA support](#23-corba-support)
- [3 Test Suite](#3-test-suite)
- [4 General Notes](#4-general-notes)

# 1. Build dependencies

Find out what Linux distribution you have via:
```bash
lsb_release --short --codename
```

Check if is supported here: [Supported Distributions](http://build.openmodelica.org/apt/dists/)

If your distribution is supported go ahead and compile the code via the commands below.
If your distribution is not supported, it might still work if you use an appropriate name instead of `lsb_release --short --codename` below.

If you are on a Windows Subsystem for Linux (WSL) we recommend using WSL2. Otherwise just
follow along the instructions below.

## 1.1 Debian/Ubuntu

Update your `sources.list`.
You might want to substitute your release name for the corresponding Debian or Ubuntu
release if your OS is based on these and there is no symbolic link in the repository yet.

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
 nightly contrib" | sudo tee -a /etc/apt/sources.list.d/openmodelica.list > /dev/null
```

To verify that the correct key is installed (optional):

```bash
gpg --show-keys /usr/share/keyrings/openmodelica-keyring.gpg
# pub   rsa2048 2010-06-22 [SC]
#       D229AF1CE5AED74E5F59DF303A59B53664970947
# uid                      OpenModelica Build System <build@openmodelica.org>
# sub   rsa2048 2010-06-22 [E]
```

Then update and install OpenModelica build dependencies:

```bash
sudo apt-get update
sudo apt-get build-dep openmodelica
```

# 2.2 Linux/BSD

First you need to install the dependencies:
- autoconf, autoreconf, automake, libtool, pkgconfig, g++, gfortran (pretty standard compilers)
- boost (optional, used with configure --with-cppruntime)
- [clang](http://clang.llvm.org/), clang++ (optional, but *highly recommended*; if you use gcc instead, use gcc 4.4 or 4.9+, not 4.5-4.8 as they are very slow)
- [cmake](http://www.cmake.org)
- hwloc (optional; queries the number of hardware CPU cores instead of logical CPU cores)
- Java JRE (JDK is option; compiles the Java CORBA interface)
- Lapack/BLAS
- libhdf5 (optional part of the [MSL](https://github.com/modelica/Modelica) tables library supported by few other Modelica tools, so it does not do much)
- libexpat (it's actually included in the FMIL sources which are included... but we do not compile those and it's better to use the OS-provided dynamically linked version)
- omniORB or mico (optional; CORBA is used by OMOptim, OMShell, and OMPython)
- libcurl (libcurl4-gnutls-dev)
- ncurses, readline (optional, used by OMShell-terminal)
- OpenSceneGraph (optional, used by OMEdit)
- Qt5 or Qt4, Webkit, QtOpenGL (optional, used by OMEdit)

# 2 Compile OpenModelica

There are two options to build OpenModelica:

  1. Use new CMake build.
  2. Use legacy Makefiles build.

If you are new or unsure what to pick, choose the new CMake build.
On OSX only the CMake build is supported.
But most of our CI is still using the old Makefiles build, so use those if you need to
reproduce some issue showing in the CI.

## 2.1 CMake build

Check [README.cmake.md](../README.cmake.md) for details, but in a nutshell run:

```bash
# (Optional) Install ccache for faster re-compilation and flex for omc-diff
sudo apt-get install ccache flex
```

```bash
cd OpenModelica
# Configure CMake, create Makefiles in build_cmake
cmake -S . -B build_cmake
# Compile with generated Makefiles
cmake --build build_cmake --parallel <Nr. of cores> --target install
```

## 2.2 Make build

Build OpenModelica compiler `omc` with C++ runtime, but without using (possibly) existing
`omc` executable:

```bash
cd OpenModelica
autoreconf --install # Or autoconf if you have autoconf <=2.69
./configure --with-cppruntime --without-omc
make -j<Nr. of cores>
```

If you want to install OpenModelica for all users you need to run `make install` with root
privileges:

```bash
cd OpenModelica
autoreconf --install # Or autoconf if you have autoconf <=2.69
# Skip some pieces of software to ease installation and only compile the base omc executable
# If you have a working and compatible omc that is not on the PATH, you can use --with-omc=path/to/omc to speed up compilation
./configure --prefix=/usr/local --disable-modelica3d
make
sudo make install
```

## 2.3 CORBA support

If you plan to use mico corba with OMC you need to:
- set the PATH to path/to/mico/bin (for the idl compiler and mico-cpp)
- set the LD_LIBRARY_PATH to path/to/installed/mico/lib (for mico libs)
- set the PATH (for executables: idl, mico-cpp and mico-config):
```bash
export PATH=${PATH}:/path/to/installed/mico/bin
```

```bash
autoreconf --install # Or autoconf if you have autoconf <=2.69
# One of the following configure lines
./configure --with-omniORB=/path/to/omniORB (if you want omc to use omniORB corba)
./configure --with-CORBA=/path/to/mico (if you want omc to use mico corba)
./configure --without-CORBA            (if you want omc to use sockets)
```


# 3 Test suite

If you compiled the OpenModelica compiler successfully you can run the test suite to check
if everything is working. Some tests are a bit fragile and depend on the OS and versions
of used 3rd-party tools. So a few failing tests don't have to be a major concern.

## 3.1 CMake

It's complicated and not yet working out of the box, see
[README.cmake.md](../README.cmake.md).

## 3.2 Make

You'll need OMSimulator in your path and a few additional dependencies:

```bash
apt install flex zip
make omsimulator
```

And then start the test suite:

```bash
make test
```

# 4 General Notes

If you run into problems open a [discussion](https://github.com/OpenModelica/OpenModelica/discussions)
or subscribe to the [OpenModelicaInterest list](https://www.openmodelica.org/index.php/home/mailing-list)
and then sent us an email at [OpenModelicaInterest@ida.liu.se](mailto:OpenModelicaInterest@ida.liu.se).

--------------

Last updated 2023-02-22.
