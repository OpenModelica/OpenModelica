# macOS Instructions

## Table of content

- [1 Build dependencies](#1-build-dependencies)
  - [1.1 MacPorts](#11-macports)
  - [1.2 Homebrew](#12-homebrew)
  - [1.3 Rust toolchain](#13-rust-toolchain)
- [2 Compile OpenModelica](#2-compile-openmodelica)
- [3 Test Suite](#3-test-suite)
- [4 Troubleshooting](#4-troubleshooting)

## 1 Build dependencies

First install the XCode command line tools:

```sh
xcode-select --install
```

We recommend installing the dependencies with `MacPorts`. It is possible to use `homebrew`
instead, but the `homebrew` instructions below build without the graphical clients (e.g.,
`OMEdit`).

### 1.1 MacPorts

Install `MacPorts` by following the instructions on
<https://guide.macports.org/#installing.macports>, then install the dependencies for
OpenModelica:

```sh
sudo port install curl libiconv gettext flex cmake ccache boost libomp openjdk11
# Qt6 for the graphical clients, needs macOS 14 or newer for QtWebEngine
sudo port install qt6-qtbase qt6-qtwebengine qt6-qt5compat qt6-qtsvg qt6-qtquick3d
```

MacPorts does not install `boost` and `libomp` where CMake looks for them, so the configure
command in [2 Compile OpenModelica](#2-compile-openmodelica) points CMake at them
explicitly.

### 1.2 Homebrew

Install `homebrew` by following the instructions on <https://brew.sh/>, then install the
dependencies for OpenModelica:

```sh
brew install openjdk pkg-config cmake make ccache boost qtwebengine qt5compat qtsvg qthttpserver qtquick3d
echo "export PATH=\"$(brew --prefix openjdk)/bin:\$PATH\"" >> ~/.zshrc
```

### 1.3 Rust toolchain

The C simulation runtime writes its result files through the Rust library `libomc_result`
and the graphical clients read them back through it. This needs `cargo` and `rustc` 1.85
or newer. Install [rustup](https://rustup.rs), e.g. with `sudo port install rustup`, and
select the stable toolchain:

```sh
rustup default stable
```

Without `cargo` on the `PATH`, CMake turns the Rust result-file library off and you lose
the `.arrow` result format; see
[4.1.1 OpenModelica Options](../README.cmake.md#411-openmodelica-options).

## 2 Compile OpenModelica

Optionally, you can install `gfortran` if you plan to use OpenModelica for dynamic
optimization purposes.

> [!NOTE]
> If you install and use `gfortran`, it is recommended that you also use `gcc` and `g++`
> (instead of `clang` and `clang++`).

If you cannot (Apple Silicon has no libquadmath) or do not want to use `gfortran`, disable
Fortran support by adding `-DOM_OMC_ENABLE_FORTRAN=OFF -DOM_OMC_ENABLE_OPTIMIZATION=OFF
-DOM_OMC_ENABLE_MOO=OFF` to the CMake configuration command.

With MacPorts, Boost is installed into a versioned directory,
`/opt/local/libexec/boost/<version>`, which `-DCMAKE_PREFIX_PATH=/opt/local` does not cover.
Find the directory holding `BoostConfig.cmake` and pass it as `Boost_DIR`:

```sh
ls -d /opt/local/libexec/boost/*/lib/cmake/Boost-*
# /opt/local/libexec/boost/1.88/lib/cmake/Boost-1.88.0
```

`libomp` puts its headers in `/opt/local/include/libomp`, so OpenMP needs `OpenMP_ROOT` and
that include directory as well.

You can now configure OpenModelica:

```sh
# With MacPorts and Fortran NOT available.
# This assumes MacPorts is installing packages to its default location /opt/local.
# Adjust Boost_DIR to the output of the ls command above.
cmake -S . -B build_cmake \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DOM_OMC_ENABLE_FORTRAN=OFF \
  -DOM_OMC_ENABLE_OPTIMIZATION=OFF \
  -DOM_OMC_ENABLE_MOO=OFF \
  -DCMAKE_PREFIX_PATH=/opt/local \
  -DBoost_DIR=/opt/local/libexec/boost/1.88/lib/cmake/Boost-1.88.0 \
  -DOpenMP_ROOT=/opt/local \
  -DCMAKE_C_FLAGS="-I/opt/local/include/libomp" \
  -DCMAKE_CXX_FLAGS="-I/opt/local/include/libomp"

# With MacPorts and Fortran available.
# Adjust Boost_DIR to the output of the ls command above.
cmake -S . -B build_cmake \
  -DCMAKE_C_COMPILER=gcc \
  -DCMAKE_CXX_COMPILER=g++ \
  -DCMAKE_Fortran_COMPILER=gfortran \
  -DCMAKE_PREFIX_PATH=/opt/local \
  -DBoost_DIR=/opt/local/libexec/boost/1.88/lib/cmake/Boost-1.88.0 \
  -DOpenMP_ROOT=/opt/local \
  -DCMAKE_C_FLAGS="-I/opt/local/include/libomp" \
  -DCMAKE_CXX_FLAGS="-I/opt/local/include/libomp"

# With homebrew.
# brew --prefix is /opt/homebrew on Apple Silicon and /usr/local on Intel.
cmake -S . -B build_cmake \
  -DCMAKE_C_COMPILER=clang \
  -DCMAKE_CXX_COMPILER=clang++ \
  -DOM_OMC_ENABLE_FORTRAN=OFF \
  -DOM_OMC_ENABLE_OPTIMIZATION=OFF \
  -DOM_OMC_ENABLE_MOO=OFF \
  -DCMAKE_PREFIX_PATH="$(brew --prefix)"
```

> [!WARNING]
> Always specify your C, C++, and Fortran (optional) compilers explicitly on macOS, **even
> when you want to use the system's default compiler**. The reason for this is that `cmake`
> does not use the default compiler `/usr/bin/c++` or `clang++`, but a version inside of
> XCode that disables the default include directories.

Once configuration finishes successfully, build and install OpenModelica:

```sh
cmake --build build_cmake --parallel <Nr. of cores> --target install
# Default install dir is a directory named install_cmake inside the build directory.
./build_cmake/install_cmake/bin/omc --help
```

See [README.cmake.md](../README.cmake.md) for the other configuration options.

## 3 Test Suite

See [6. Running Tests](../README.cmake.md#6-running-tests) in README.cmake.md. Many tests
only pass on Linux, so expect some failures on macOS.

## 4 Troubleshooting

If you encounter errors while configuring, building, or simulating with OpenModelica, read
on below.

- If configuration fails due to missing packages, e.g. Qt components, add the MacPorts
  root packages directory to `CMAKE_PREFIX_PATH`. Run

  ```sh
  port contents qt6-qtbase
  ```

  to see the directory. Then add the base directory of the result (`/opt/local` by default)
  to `CMAKE_PREFIX_PATH`:

  ```sh
  cmake ... -DCMAKE_PREFIX_PATH=/opt/local ...
  ```

- If configuration fails with `Could NOT find Boost` even though `CMAKE_PREFIX_PATH`
  includes `/opt/local`, CMake is not looking in the versioned MacPorts Boost directory.
  Set `Boost_DIR` as shown in [2 Compile OpenModelica](#2-compile-openmodelica).
  Alternatively, `-DOM_FETCH_BOOST=ON` downloads and builds Boost as part of OpenModelica.
  That option is meant for cross builds and has not been tested on macOS.

- If OpenMP is not found, or compilation fails with `'omp.h' file not found`, install
  `libomp` and add `-DOpenMP_ROOT=/opt/local` together with
  `-DCMAKE_C_FLAGS="-I/opt/local/include/libomp" -DCMAKE_CXX_FLAGS="-I/opt/local/include/libomp"`.
  When you reconfigure an existing build directory, delete `build_cmake/CMakeCache.txt`
  first, so the failed lookups are not reused from the cache. If you cannot get OpenMP to
  work, `-DOM_OMC_ENABLE_COLPACK=OFF` is what the macOS CI build uses instead.

- If your compilation fails because of linking issues with `libiconv`:

  ```text
  [ 30%] Linking CXX executable bootstrapped/bin/bomc
  ld: warning: dylib (/opt/homebrew/lib/libintl.dylib) was built for newer macOS version (13.0) than being linked (12.3)
  Undefined symbols for architecture arm64:
    "_libiconv", referenced from:
        _SystemImpl__iconv in libomcruntime.a(System_omc.c.o)
    "_libiconv_close", referenced from:
        _SystemImpl__iconv in libomcruntime.a(System_omc.c.o)
    "_libiconv_open", referenced from:
        _SystemImpl__iconv in libomcruntime.a(System_omc.c.o)
  ld: symbol(s) not found for architecture arm64
  clang: error: linker command failed with exit code 1 (use -v to see invocation)
  ```

  the compilation might be using `libiconv` from XCode (which contains functions not
  prefixed with `lib`, i.e., `_iconv_open` instead of `_libiconv_open`). Reconfigure
  OpenModelica with the MacPorts base directory as a prefix path for CMake:

  ```sh
  cmake ... -DCMAKE_PREFIX_PATH=/opt/local ...
  ```

  This gives it priority over the XCode one and CMake will pick up the MacPorts `libiconv`.

- If your compilation fails because of linking issues such as these:

  ```text
  ld: warning: ignoring file /opt/local/lib/libboost_filesystem-mt.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64
  ```

  then check your `PATH` and set it to something sane like:

  ```sh
  export PATH=/usr/bin:/bin:/usr/sbin:/sbin:$PATH
  ```

  then clean OpenModelica

  ```sh
  cd OpenModelica
  git clean -ffdx
  git submodule foreach --recursive git clean -ffdx
  ```

  and start again with the commands above.

- If building simulation code fails because your compiler cannot find `stdio.h`, then do
  one of the following:
  - If you have not already, make sure you have specified your C and C++ compilers
    explicitly when configuring OpenModelica (see above). Reconfigure and recompile
    OpenModelica.
  - If you do not want to reconfigure and build, you can instead manually change the
    compilers used by OMEdit (for example) by going to `Tools -> Options -> Simulation` and
    adjusting the `C Compiler` and `CXX Compiler` fields, i.e., they should NOT be
    `/usr/bin/cc` and `/usr/bin/c++`.
  - Another option is to set the proper `SDKROOT` and `PATH` in a terminal before starting
    OMEdit:

    ```sh
    export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin:$PATH
    ```
