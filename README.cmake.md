
- [1. General Information](#1-general-information)
- [2. ccache](#2-ccache)
- [3. Usage](#3-usage)
  - [3.1. General Notes](#31-general-notes)
  - [3.2. Linux](#32-linux)
  - [3.3. Windows MSYS/MinGW](#33-windows-msysmingw)
  - [3.4. Generic Usage.](#34-generic-usage)
- [4. Configuration Options.](#4-configuration-options)
  - [4.1. OpenModelica Specific Configuration Options](#41-openmodelica-specific-configuration-options)
    - [4.1.1. OpenModelica Options](#411-openmodelica-options)
    - [4.1.2. OpenModelica/OMCompiler Options](#412-openmodelicaomcompiler-options)
    - [4.1.3. OpenModelica/OMEdit Options](#413-openmodelicaomedit-options)
  - [4.2. Selecting a Compiler.](#42-selecting-a-compiler)
  - [4.3. Disabling Colors for Makefile Generators](#43-disabling-colors-for-makefile-generators)
  - [4.4. Enabling Verbose Output](#44-enabling-verbose-output)
- [5. Integration with Editors/Tools](#5-integration-with-editorstools)
- [6. Running Tests (rtest)](#6-running-tests-rtest)

# 1. General Information
If you are used to the default `autotools + Makefile` build system that omc is using right now, there is one conceptual point to keep in mind. Building and installing are seaprate processes with the CMake build system. This means, to use `omc` (or most other executable targets, e.g, `OMEdit`, `OMPlot` ...), you have to build and then install the project. The build folder structure does not represent or match the final structure `omc` expects when it is used. The `autotools + Makefile` build system we are using now has these two steps combined in to one. The good news is that CMake also provides an install target always. So if you are used to issuing

```
make omc
```

to build and install a usable omc in one step, you now have to use

```
make install
```

instead. In addition now you have run omc from the **install** dir instead of the **build** dir.

By default, if you do not specify anything, the configuration will chose an installation directory named `install_cmake` inside of your build dir.

To summarize, if you have a fresh copy of OpenModelica and want to get started, this would be one possible process you can follow

```sh
mkdir build_cmake && cd build_cmake
cmake ..
make install

# Default install dir is a directory named install_cmake inside the build directory.
./install_cmake/bin/omc --help
```

with a little variation but equivalently with the same result

```sh
mkdir build_cmake
cmake -S . -B build_cmake
make -C build_cmake install

# Default install dir is a directory named install_cmake inside the build directory.
./build_cmake/install_cmake/bin/omc --help
```

# 2. ccache
[ccache](https://ccache.dev/) is a compiler cache. It speeds up recompilation by caching previous compilations and detecting when the same compilation is being done again.

Technically speaking it is not a blocking requirement but in paractice you should assume it is. If it is available for your system you should use it.

MetaModelica compilation involves a lot of recompilation of unmodified C files because of new time stamps for generated header files. ccache will practically reduce the cost of these types of recompilations to a no-op.

It is available for linux (of course) and, fortunatelly, for MSYS/MinGW as well (mingw-w64-x86_64-ccache and mingw-w64-i686-ccache). It is not part of OMDev at the moment but it will be in the next iteration.

# 3. Usage
## 3.1. General Notes
- In source build is forbidden.

- Use `-Wno-dev` to silence CMake warnings from 3rdParty libraries.
  ```
  cmake .. -Wno-dev
  ```

 - Your build directory should NOT be a directory named `build` in the root OpenModelica directory.

   The reason for this suggestion is that the `autotools + Makefile` build system we have now uses this `build` directory for _installation_. Therefore, if you plan to fallback to the autotools build at some point or you want to switch back and forth between the CMake and autotools build systems (perhaps to cross check something), then it is probably a good idea to make sure that they do not overwrite eachother's outputs.
## 3.2. Linux
There is nothing special to be done for linux. You can follow the examples above or chose your own combination of parameters (e.g. build type, generator, install dir ...).

## 3.3. Windows MSYS/MinGW
There is also nothing special about MSYS/MinGW if you are familiar with it. Just a few hints:

  - The generator should to be "MSYS Makefiles". This is not what CMake chooses by default for Windows.
  - You might want to make sure the output colors do not get mingled for Makefile target generation.

Considering these, your final configure and build lines would be

```sh
mkdir build_cmake && cd build_cmake
cmake .. -Wno-dev -G "MSYS Makefiles"
make -j9 install -Oline

# Default install dir is a directory named install_cmake inside the build directory.
./install_cmake/bin/omc --help
```
`-Oline` instructs GNU Make to print outputs one line at a time, makeing sure ANSI color codes do not get interleaved. **Note that** with this flag ON, a Makefile step is printed once it is **completed**, not when it is issued. So if you see something taking a long time, it is probably the thing that is printed right after which is actually the culprit.


## 3.4. Generic Usage.
If you want to follow a process that is "generator" agnostic, e.g., if you are writing a script that should run across platforms, you can explicitly use the CMake versions of the build commands instead of the generator specific ones.

```sh
cmake -S . -B build_cmake
cmake --build build_cmake --parallel 9 --target install

# Default install dir is a directory named install_cmake inside the build directory.
./build_cmake/install_cmake/bin/omc --help
```


# 4. Configuration Options.

## 4.1. OpenModelica Specific Configuration Options
There are a handful OpenModelica specific options that you can adjust to your needs.

The main ones (with their default values) are
```cmake
OM_USE_CCACHE=ON
OM_ENABLE_GUI_CLIENTS=ON
OM_OMC_ENABLE_CPP_RUNTIME=ON
OM_OMEDIT_INSTALL_RUNTIME_DLLS=ON
```
### 4.1.1. OpenModelica Options
`OM_USE_CCACHE` option is for enabling/desabling ccache support as explained in [2. ccache](#2-ccache). It is recommended that you install ccache and set this to ON.

`OM_ENABLE_GUI_CLIENTS` allows you to enable/disable the configuration and build of the qt based GUI clients and their dependencies. These include: OMEdit, OMNotebook, OMParser, OMPlot, OMShell. You will need to install and make available the necessary packages (and their dependencies) such as the Qt libs, OpenSceneGraph, OpenThreads ...

**Hint**: You might be tempted to disable these optional components in order to reduce re-compilation time when you are workign on something unrelated. For example, if you have been using the `autotools` build system, you might have noticed that re-compilation will take additional time due to CPP runtime or OMEdit even though you have not modified nothing in there. **The recommendation now is to have everything enabled** IF you have the required packages installed anyway (Qt libs and boost). Re-compilation will not take any significant additional time on things you have not modified. If you have ccache available it is even better as recompilation after a clean (with no new modifications) will also be extremely fast.

### 4.1.2. OpenModelica/OMCompiler Options
`OM_OMC_ENABLE_CPP_RUNTIME` allows you to enable/disable the building of the C++ based simulation runtime. This will require multiple Boost library components (file_system, program_options, ...)

### 4.1.3. OpenModelica/OMEdit Options
`OM_OMEDIT_INSTALL_RUNTIME_DLLS` allows you to enable/disable the installation of the required runtime DLLs for MSYS/MinGW builds. The
only reason to disable this would be if you plan to start/launch all the GUI executables exclusively from a MSYS/MinGW shell and never
from the Windows explorer.


There are also some additional options that are kept as a migration step to maintain the similarity with the `autotools` build system.

```cmake
OM_OMC_BUILD_LPSOLVE=OFF
OM_OMC_USE_LPSOLVE=OFF
OM_OMC_USE_CORBA=OFF
OM_OMC_USE_LAPACK=ON
```

These options are not guaranteed to work properly if they are changed from their default values as of now.

## 4.2. Selecting a Compiler.
If you, for example, want to use clang instead of GCC, you can do so by modifying `CMAKE_<LANG>_COMPILER`
```sh
cmake .. -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++
```

CMake picks up the default compiler by checking for CC/CXX in your environment. This means you can also achieve the same thing by modifying the environment just for the current CMake invocation:

```sh
CC=clang CXX=clang++ cmake ..
```

## 4.3. Disabling Colors for Makefile Generators
If you do not like colors you can disable them.
```sh
cmake .. -DCMAKE_COLOR_MAKEFILE=OFF
```

This can be useful if you want to redirect output to a file for example.

## 4.4. Enabling Verbose Output
Sometimes you might want to get a verbose output to see what CMake is actually doing and what exact commands it is issuing.

For Makefile generators (which, probably, is by far the most common usage), you can tell GNU Make itself to give you verbose output at compile time
```sh
make VERBOSE=1
```

This has the advantage of allowing you to get verbose output only when you want it.

If you instead want to see verbose output every time you compile any change then you can tell CMake at configure time to always do that

```sh
cmake .. -DCMAKE_VERBOSE_MAKEFILE=ON
```

# 5. Integration with Editors/Tools
The CMake configuration is set to always generate the compile command-line for each target it discovers in to a file named `compile_commands.json`. This file is known and understood by a number of editors and tools such as vscode, Vim, emacs, clang-tidy ...

Editors can use this file to give you a better interpretation of your source files. For example, #includes can now be pinpointed because the editor knows exactly which includes directories are given to the file when compiled. It can also understand things like CXX stadnards and preprocessor defines enabled on command line ...

Some editors and tools will check for the existence of this file automatically. If not, it is recommended that you check your editor instructions to see if you can take advantage of it.

# 6. Running Tests (rtest)

Running the entirety of the OpenModelica testsuite is a complicated process and outside the scope for now. So there is no `ctest` support yet and CMake does not run any tests for you. In other words, you can not expect to test the sanity of your compilation by doing something like `make test`.

However, you can and should modify `rtest` to pick up the omc compiled by your CMake build system. By default `rtest` will look for omc in `<OpenModelica>/build/`. Therefore it needs to be modified to look for omc in your specified `CMAKE_INSTALL_PREFIX` which by default will be `<OpenModelica>/<build_dir>/install_cmake/` if you have not specified another `CMAKE_INSTALL_PREFIX`.

Find the line
```
$OPENMODELICAHOME="$1build";
```

and change it to something like
```
$OPENMODELICAHOME="$1build_cmake/install_cmake";
```


