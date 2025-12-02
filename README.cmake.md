# OpenModelica CMake build instructions

- [OpenModelica CMake build instructions](#openmodelica-cmake-build-instructions)
- [1. Quick start](#1-quick-start)
- [2. ccache](#2-ccache)
- [3. Usage](#3-usage)
  - [3.1. General Notes](#31-general-notes)
  - [3.2. Linux](#32-linux)
  - [3.3. macOS](#33-macos)
    - [3.3.1 Setup](#331-setup)
      - [3.3.1.1 MacPorts](#3311-macports)
      - [3.3.1.2 Homebrew](#3312-homebrew)
    - [3.3.2 Building](#332-building)
    - [3.3.3 Common macOS issues](#333-common-macos-issues)
  - [3.4. Windows MSYS/UCRT64](#34-windows-msysucrt64)
- [4. Configuration Options.](#4-configuration-options)
  - [4.1. OpenModelica Specific Configuration Options](#41-openmodelica-specific-configuration-options)
    - [4.1.1. OpenModelica Options](#411-openmodelica-options)
    - [4.1.2. OpenModelica/OMCompiler Options](#412-openmodelicaomcompiler-options)
    - [4.1.3. OpenModelica/OMEdit Options](#413-openmodelicaomedit-options)
    - [4.1.4. OpenModelica/OMShell Options](#414-openmodelicaomshell-options)
    - [4.1.4. Other OpenModleica specific Options](#414-other-openmodleica-specific-options)
  - [4.2. Useful CMake Configuration Options](#42-useful-cmake-configuration-options)
    - [4.2.1. Disabling Colors for Makefile Generators](#421-disabling-colors-for-makefile-generators)
    - [4.2.2 Enabling Verbose Output](#422-enabling-verbose-output)
- [5. Integration with Editors/Tools](#5-integration-with-editorstools)
- [6. Running Tests (rtest)](#6-running-tests-rtest)

# 1. Quick start

We recommend you read the instructions for your Operating System as they contain some tips
and workarounds for some common pitfalls.

That said, if you are familiar with CMake and have all the dependencies installed you can
compile OpenModelica using the standard CMake flow.

```sh
git clone --recurse-submodules https://github.com/OpenModelica/OpenModelica.git
cd OpenModelica
cmake -S . -B build_cmake
# Build using cmake's generic commands.
cmake --build build_cmake --target install --parallel <Nr. of cores>
# OR build using the command for your generator directly, e.g., Makefiles based
# cd build_cmake
# make -j <Nr. of cores> install

# Default install dir is a directory named install_cmake inside the build directory.
./build_cmake/install_cmake/bin/omc --help
```

By default, if you do not specify anything, the configuration will chose an installation
directory named `install_cmake` inside of your build dir.

# 2. ccache
[ccache](https://ccache.dev/) is a compiler cache. It speeds up recompilation by caching
previous compilations and detecting when the same compilation is being done again.

Technically speaking it is not a blocking requirement but in paractice you should assume
it is. If it is available for your system you should use it.

MetaModelica compilation involves a lot of recompilation of unmodified C files because of
new time stamps for generated header files. ccache will practically reduce the cost of
these types of recompilations to a no-op.

It is available for Linux (of course) and, fortunately, for MSYS/UCRT64 as well
(mingw-w64-ucrt-x86_64-ccache).

# 3. Usage
## 3.1. General Notes

- In source build is not recommended. Always create a dedicated build directory, e.g.
  `OpenModelica/build_cmake`

- Add `-Wno-dev` to your CMake configuration command to silence CMake warnings from
  3rdParty libraries.
  ```
  cmake .. -Wno-dev
  ```

 - Your build directory should NOT be a directory named `build` in the root OpenModelica
   directory.

   The reason for this suggestion is that the `autotools + Makefile` build system we have
   now uses this `build` directory for _installation_. Therefore, if you plan to fallback
   to the autotools build at some point or you want to switch back and forth between the
   CMake and autotools build systems (perhaps to cross check something), then it is
   probably a good idea to make sure that they do not overwrite eachother's outputs.

## 3.2. Linux

There is nothing special to be done for linux. Once you have installed all the
dependencies (If you need help, follow the instructions
[here](https://github.com/OpenModelica/OpenModelica/blob/master/OMCompiler/README.Linux.md)
**excluding** the configuration steps, `autoconf`, ...), you can follow the instruction in
[quick start](#1-quick-start) section above or choose your own combination of
[configuration options](#4-configuration-options) (e.g. build type, generator, install dir ...).

## 3.3. macOS

### 3.3.1 Setup
On macOS you need to install: XCode and `MacPorts`. It is possible to use `homebrew` instead of `MacPorts`. However you will not be able to build the Graphical Clients (e.g., `OMEdit`) with just `homebrew` because one of the dependencies, `QTWebKit`, is not available through `homebrew` any longer.

First you need to install XCode

  ```sh
  xcode-select –-install
  ```
#### 3.3.1.1 MacPorts

Next install `MacPorts` by following the instructions on https://guide.macports.org/#installing.macports.

Once XCode and macports are installed, you need to install the dependencies for OpenModelica using `MacPorts`:

  ```sh
  sudo port install curl libiconv gettext flex cmake ccache qt5 qt5-qtwebkit autoconf boost OpenSceneGraph openjdk11
  ```

#### 3.3.1.2 Homebrew

If you want to use only `homebrew` instead of `MacPorts` (remember that you will not be able to build the GUI clients this way), then follow the instructions on https://brew.sh/ to install homebrew. Once that is done, install the dependencies for OpenModelica using `homebrew`:

  ```sh
  brew install autoconf automake openjdk pkg-config cmake make ccache
  echo 'export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"' >> ~/.zshrc
  ```

### 3.3.2 Building

Optionally, You can also install `gfortran` if you plan to use OpenModelica for dynamic optimization purposes.

> **Note**
> If you install and use `gfortran`, it is recommended that you also use `gcc` and `g++`
> (instead of `clang` and `clang++`).

If you cannot (M1 Mac does not have libquadmath) or do not want to use `gfortran`, then you should disable Fortran support by adding ```-DOM_OMC_ENABLE_FORTRAN=OFF -DOM_OMC_ENABLE_OPTIMIZATION=OFF -DOM_OMC_ENABLE_MOO=OFF``` to the CMake configuration command.

You can now configure and compile OpenModelica as:

  ```sh
  # With MacPorts and Fortran available. This assumes MacPorts is installing packages to its default location /opt/local
  cmake -S . -B build_cmake -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_Fortran_COMPILER=gfortran -DCMAKE_PREFIX_PATH=/opt/local
  # (M1 Mac does not have libquadmath)
  # With MacPorts and Fortran NOT available. This assumes MacPorts is installing packages to its default location /opt/local
  cmake -S . -B build_cmake -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DOM_OMC_ENABLE_FORTRAN=OFF -DOM_OMC_ENABLE_OPTIMIZATION=OFF -DOM_OMC_ENABLE_MOO=OFF -DCMAKE_PREFIX_PATH=/opt/local
  # With homebrew, you also need to disable the graphical clients. This assumes homebrew is installing packages to its default location /usr/local/opt/
  cmake -S . -B build_cmake -D CMAKE_C_COMPILER=clang -D CMAKE_CXX_COMPILER=clang++ -DOM_OMC_ENABLE_FORTRAN=OFF -DOM_OMC_ENABLE_OPTIMIZATION=OFF -DOM_OMC_ENABLE_MOO=OFF -D OM_ENABLE_GUI_CLIENTS=OFF -DCMAKE_PREFIX_PATH=/usr/local/opt/
  ```

> **Warning**
> Always specify your C, C++, and Fortran (optional) compilers explicitly on macOS.

> **Warning**
> This applies **even when you want to use the systems default compiler**. The reason for
> this is that `cmake` does not use the default compiler `/usr/bin/c++` or `clang++`, but
> an a version inside of XCode that disables the default include directories.

Once configuration finishes successfully you can build OpenModelica as you would on any
unix system, e.g.,

  ```sh
  cmake --build build_cmake --parallel <Nr. of cores> --target install
  # Default install dir is a directory named install_cmake inside the build directory.
  ./build_cmake/install_cmake/bin/omc --help
  ```

### 3.3.3 Common macOS issues

If you encounter some errors while configuring, building, or simulating-with OpenModelica read on below. On macOS there are a few pitfalls/issues which need attention.

- If configuration fails due to missing packages, e.g. Qt components, add the macports
  root packages directory to CMAKE_PREFIX_PATH. Run

  ```sh
  $ port contents qt5
  Port qt5 contains:
    /opt/local/share/doc/qt5/README.txt
  ```
  to see the directory. Then add the base directory of the result (/opt/local by default) to CMAKE_PREFIX_PATH by specifying

  ```sh
  $ cmake ... -DCMAKE_PREFIX_PATH=/opt/local ...
  ```

- If your compilation fails because of linking issues with `libiconv``:
  ```sh
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

  the compilation might be using `libiconv` from XCode (which contains functions not prefixed with `lib`, i.e., `_iconv_open` instead of `_libiconv_open`). Try reconfiguring OpenModelica by adding the MacPorts base directory as a prefix path for CMake.

  ```sh
  $ cmake ... -DCMAKE_PREFIX_PATH=/opt/local ...
  ```

  This will give it priority over the XCode one and CMake will pick up the MacPorts `libiconv`.


- If your compilation fails because of linking issues such as these:

  ```ld: warning: ignoring file /opt/local/lib/libboost_filesystem-mt.dylib, building for macOS-x86_64 but attempting to link with file built for macOS-arm64```

  then check your $PATH and set it to something sane like:

  ```export PATH=/usr/bin:/bin:/usr/sbin:/sbin:$PATH```

  then clean OpenModelica
  ```sh
  cd OpenModelica
  git clean -ffdx
  git submodule foreach --recursive git clean -ffdx
  ```
  and start again with the commands above.

- If building simulation code fails because your compiler cannot find ```stdio.h``` then do one of the following:
  - If you have not already, make sure you have specified your C and C++ compilers
    explicitly when configuring OpenModelica (see above). Reconfigure and recompile
    OpenModelica.
  - If you do not want to reconfigure and build, you can instead manually change the
    compilers used by OMEdit (for example) by going to `Tools -> options -> Simulation` and
    adjusting `C Compiler` and `CXX Compiler` fields, i.e., they should NOT be
    `usr/bin/cc` and `/usr/bin/c++`.
  - Another option is to set the proper SDKROOT and PATH in a terminal before starting OMEdit:

    ```sh
    export SDKROOT=$(xcrun --sdk macosx --show-sdk-path)
    export PATH=/usr/bin:/bin:/usr/sbin:/sbin:$PATH
    ```

## 3.4. Windows MSYS/UCRT64

There is nothing special about MSYS/UCRT64 if you are familiar with it. Just a few hints:

  - The generator should be "MSYS Makefiles". This is not what CMake chooses by default
    for Windows.
  - You might want to make sure the output colors do not get mingled for Makefile target
    generation.

Considering these, your final configure and build lines would be

```sh
cd OpenModelica
cmake -S . -B build_cmake -Wno-dev -G "MSYS Makefiles"
cd build_cmake
make -j9 install -Oline

# Default install dir is a directory named install_cmake inside the build directory.
./install_cmake/bin/omc --help
```
> **Note**
> `-Oline` instructs GNU Make to print outputs one line at a time, makeing sure ANSI color
> codes do not get interleaved.

> **Note**
> With `-Oline` added, a Makefile step is printed once it is **completed**, not when it is
> issued. So if you see something taking a long time, it is probably the thing that is
> printed right after which is actually the culprit.

# 4. Configuration Options.

## 4.1. OpenModelica Specific Configuration Options
There are a handful OpenModelica specific options that you can adjust to your needs.

The main ones (with their default values) are
```cmake
OM_USE_CCACHE=ON
OM_ENABLE_GUI_CLIENTS=ON
OM_ENABLE_ENCRYPTION=OFF
OM_OMC_ENABLE_CPP_RUNTIME=ON
OM_OMC_ENABLE_FORTRAN=ON
OM_OMC_ENABLE_OPTIMIZATION=ON
OM_OMC_ENABLE_MOO=ON
OM_OMEDIT_INSTALL_RUNTIME_DLLS=ON
OM_OMEDIT_ENABLE_TESTS=OFF
OM_OMSHELL_ENABLE_TERMINAL=ON
```

### 4.1.1. OpenModelica Options

`OM_USE_CCACHE` option is for enabling/disabling ccache support as explained in
[2. ccache](#2-ccache). It is recommended that you install ccache and set this to ON.

`OM_ENABLE_GUI_CLIENTS` allows you to enable/disable the configuration and build of the qt
based GUI clients and their dependencies. These include: OMEdit, OMNotebook, OMParser,
OMPlot, OMShell. You will need to install and make available the necessary packages (and
their dependencies) such as the Qt libs, OpenSceneGraph, OpenThreads ...

`OM_ENABLE_ENCRYPTION` allows you to enable/disable building OpenModelica with library
encryption support. Note that, for this to work, you need an additional module which is
not distributed in the default OpenModelcia source repository. Contact the OpenModelica
team if you need encryption support.

### 4.1.2. OpenModelica/OMCompiler Options

`OM_OMC_ENABLE_CPP_RUNTIME` allows you to enable/disable the building of the C++ based
simulation runtime. This requires multiple Boost library components (file_system,
program_options, ...)

`OM_OMC_ENABLE_FORTRAN` allows you to enable/disable Fortran support. If your system does
not have a Fortran compiler you can disable this. Fortran is required if you enable IPOPT
support (`OM_OMC_ENABLE_OPTIMIZATION`, `OM_OMC_ENABLE_MOO`).

`OM_OMC_ENABLE_OPTIMIZATION` allows you to enable/disable support for dynamic optimization
support with Ipopt. Enabling this requires having a working Fortran compiler and requires
MOO (`OM_OMC_ENABLE_MOO`).

`OM_OMC_ENABLE_MOO` allows you to enable/disable support for dynamic optimization
support with MOO. Enabling this requires having a working Fortran compiler.

### 4.1.3. OpenModelica/OMEdit Options

`OM_OMEDIT_ENABLE_TESTS` Enable testing and build the OMEdit Testsuite.

`OM_OMEDIT_INSTALL_RUNTIME_DLLS` allows you to enable/disable the installation of the
required runtime DLLs for MSYS/UCRT64 builds.

### 4.1.4. OpenModelica/OMShell Options

`OM_OMSHELL_ENABLE_TERMINAL` allows you to enable/disable the building of the
OMShell-terminal command-line REPL application. This requires the GNU readline library.
Note that this is different from the Qt based OMShell GUI application.

### 4.1.4. Other OpenModleica specific Options

There are also some additional options that are kept as a migration step to maintain the
similarity with the `autotools` build system.

```cmake
OM_OMC_USE_CORBA=OFF
OM_OMC_USE_LAPACK=ON
```

These options are not guaranteed to work properly if they are changed from their default
values as of now.

## 4.2. Useful CMake Configuration Options
### 4.2.1. Disabling Colors for Makefile Generators

If you do not like colors you can disable them.

```sh
cmake .. -DCMAKE_COLOR_MAKEFILE=OFF
```

This can be useful if you want to redirect output to a file for example.

### 4.2.2 Enabling Verbose Output

Sometimes you might want to get a verbose output to see what CMake is actually doing and
what exact commands it is issuing.

If you are using CMake itself to issue builds (recommended) instead of invoking the
generator directly, you can specify `-v` to the build command

```sh
cmake --build build_cmake -v
```

For Makefile generators (which, probably, is by far the most common usage), you can tell
GNU Make itself to give you verbose output at compile time:

```sh
make VERBOSE=1
```

The above two approaches have the advantage of allowing you to get verbose output only
when you want it.


If you instead want to see verbose output every time you compile any change then you can
tell CMake at configure time to always do that:

```sh
cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON
```

# 5. Integration with Editors/Tools

The CMake configuration is set to always generate the compile command-line for each target
it discovers in to a file named `compile_commands.json`. This file is known and understood
by a number of editors and tools such as vscode, Vim, emacs, clang-tidy ...

Editors can use this file to give you a better interpretation of your source files. For
example, #includes can now be pinpointed because the editor knows exactly which includes
directories are given to the file when compiled. It can also understand things like CXX
stadnards and preprocessor defines enabled on command line ...

Some editors and tools will check for the existence of this file automatically. If not, it
is recommended that you check your editor instructions to see if you can take advantage of
it.

# 6. Running Tests (rtest)

Running the entirety of the OpenModelica testsuite is a complicated process and outside
the scope for now.
So there is no `ctest` support yet and CMake does not run any tests for you.
In other words, you can not expect to test the sanity of your compilation by doing
something like `make test`.

However, you can and should modify `rtest` to pick up the omc compiled by your CMake build
system.
By default `rtest` will look for omc in `<OpenModelica>/build/`. Therefore it needs to be
modified to look for omc in your specified `CMAKE_INSTALL_PREFIX` which by default will be
`<OpenModelica>/<build_dir>/install_cmake/` if you have not specified another
`CMAKE_INSTALL_PREFIX`.

Find the line

```perl
$OPENMODELICAHOME="$1build_cmake/install_cmake";
```

and adjust it to point to the installation directory you have specified when configuring
OpenModelica, e.g.,

```perl
$OPENMODELICAHOME="$1build_cmake_release/install_cmake";
```
