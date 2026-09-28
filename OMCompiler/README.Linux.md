# Linux/WSL Instructions

## Table of content

- [1 Build dependencies](#1-build-dependencies)
  - [1.1 Debian/Ubuntu](#11-debianubuntu)
  - [1.2 Other Linux/BSD](#12-other-linuxbsd)
  - [1.3 Rust toolchain](#13-rust-toolchain)
- [2 Compile OpenModelica](#2-compile-openmodelica)
- [3 Test Suite](#3-test-suite)
- [4 General Notes](#4-general-notes)

## 1 Build dependencies

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

### 1.2 Other Linux/BSD

Install the following dependencies with your package manager:

- [cmake](https://cmake.org), g++ or [clang](https://clang.llvm.org/)/clang++, pkg-config
- gfortran (optional, see `OM_OMC_ENABLE_FORTRAN` in
  [README.cmake.md](../README.cmake.md#412-openmodelicaomcompiler-options))
- ccache (optional, but _highly recommended_) and flex (for `omc-diff`, used by the test
  suite)
- Java Development Kit (for the parser generator)
- boost (C++ simulation runtime and ParModelica)
- Lapack/BLAS
- libcurl (libcurl4-gnutls-dev), libuuid, gettext
- libhdf5 (optional, MAT v7.3 result files, see `OM_ENABLE_HDF5`)
- ncurses, readline (optional, used by OMShell-terminal)
- Qt6 with QtWebEngine, Qt5Compat, QtQuick3D (optional, used by OMEdit) and QtSvg (optional, used by the graphical clients)
- rustc and cargo (see [1.3 Rust toolchain](#13-rust-toolchain))

### 1.3 Rust toolchain

Parts of OpenModelica are written in Rust, so `cargo` and `rustc` are needed to
build it: result files are read and written through `libomc_result`, and
`--simCodeTarget=C` links the Rust simulation runtime.

Any reasonably recent stable toolchain will do. The crates use the 2024 edition,
so `rustc`/`cargo` 1.85 or newer:

```bash
sudo apt-get install rustc cargo
cargo --version
```

If your distribution packages something older (Ubuntu 24.04 for instance),
install [rustup](https://rustup.rs) and let it manage the toolchain instead:

```bash
sudo apt-get install rustup
# Or, if there is no rustup package:
# curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default stable
```

`-DOM_OMC_ENABLE_RUST=ON` builds the compiler itself as the Rust port, which
needs the pinned nightly toolchain described in
[Compiler/OpenModelica.rs/README.md](Compiler/OpenModelica.rs/README.md).

## 2 Compile OpenModelica

OpenModelica is built with CMake. Check [README.cmake.md](../README.cmake.md) for the
configuration options, but in a nutshell run:

```bash
# (Optional) Install ccache for faster re-compilation and flex for omc-diff
sudo apt-get install ccache flex
```

```bash
cd OpenModelica
# Configure CMake, create Makefiles in build_cmake
cmake -S . -B build_cmake
# Compile and install into build_cmake/install_cmake
cmake --build build_cmake --parallel <Nr. of cores> --target install
./build_cmake/install_cmake/bin/omc --help
```

## 3 Test Suite

If you compiled the OpenModelica compiler successfully you can run the test
suite to check if everything is working. Some tests are a bit fragile and depend
on the OS and versions of used 3rd-party tools. So a few failing tests don't
have to be a major concern.

See [6. Running Tests](../README.cmake.md#6-running-tests) in README.cmake.md.

## 4 General Notes

If you run into problems open a
[discussion](https://github.com/OpenModelica/OpenModelica/discussions)
or subscribe to the
[OpenModelicaInterest list](https://www.openmodelica.org/index.php/home/mailing-list)
and then send us an email at
[OpenModelicaInterest@ida.liu.se](mailto:OpenModelicaInterest@ida.liu.se).
