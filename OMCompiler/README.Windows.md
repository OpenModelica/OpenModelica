# Windows Instructions

## Table of content

- [1 MSYS2](#1-msys2)
  - [1.1 General Notes](#11-general-notes)
  - [1.2 Install MSYS2 packages](#12-install-msys2)
  - [1.3 Install Additional Programs](#13-install-additional-programs)
  - [1.4 Environment Variables](#14-environment-variables)
- [2 Compile OpenModelica](#2-compile-openmodelica)
  - [2.1 MSYS and CMake](#21-msys-and-cmake)
  - [2.2 MSYS and Make](#22-msys-and-make)
- [3 Installer](#3-installer)
- [4 Test Suite](#4-test-suite)
- [5 Troubleshooting](#5-troubleshooting)

# 1 MSYS2

We use Linux tools to compile OpenModelica on Windows.
For that you'll need to install [MSYS2](https://www.msys2.org/) with
[UCRT64](https://www.msys2.org/docs/environments/) environment.

Follow the installation instructions in [www.msys2.org](https://www.msys2.org/) to install
MSYS2 with the installer in `C:\OMDEV\tools\msys64`.

## 1.1 General Notes

  - Install Git for Windows https://git-scm.com/downloads
    Do not install git using pacman in msys, it does not work correctly!
  - Make sure you git clone with the correct line endings, run in a (Git Bash) terminal:
    ```bash
      git config --global core.eol lf
      git config --global core.autocrlf input
    ```

## 1.2 Install MSYS2

These are the UCRT64 packages needed to build OpenModelica:

  - zip
  - unzip
  - make
  - libtool
  - flex
  - mingw-w64-ucrt-x86_64-make
  - mingw-w64-ucrt-x86_64-cmake
  - mingw-w64-ucrt-x86_64-ccache
  - mingw-w64-ucrt-x86_64-gcc-fortran
  - mingw-w64-ucrt-x86_64-gcc-libs
  - mingw-w64-ucrt-x86_64-binutils
  - mingw-w64-ucrt-x86_64-curl
  - mingw-w64-ucrt-x86_64-libiconv
  - mingw-w64-ucrt-x86_64-readline
  - mingw-w64-ucrt-x86_64-expat
  - mingw-w64-ucrt-x86_64-libsystre
  - mingw-w64-ucrt-x86_64-winpthreads-git
  - mingw-w64-ucrt-x86_64-opencl-headers
  - mingw-w64-ucrt-x86_64-openblas

Optional packages for GUI (e.g OMEdit):

  - mingw-w64-ucrt-x86_64-qt5
  - mingw-w64-ucrt-x86_64-qtwebkit
  - mingw-w64-ucrt-x86_64-OpenSceneGraph
    or mingw-w64-ucrt-x86_64-OpenSceneGraph-debug for the debug version.
  - mingw-w64-ucrt-x86_64-gdb

Optional packages for CPP runtime

  - mingw-w64-ucrt-x86_64-boost

Optional packages for OMSens

  - mingw-w64-ucrt-x86_64-python-numpy

Optional packages for OMTLMSimulator

  - mingw-w64-ucrt-x86_64-libxml2

Optional compiler

  -  mingw-w64-ucrt-x86_64-clang

Start the bash command line with the UCRT64 environment `C:\OMDev\tools\msys64\ucrt64.exe`
and use `pacman` to install the packages:

```bash
# Needed
pacman -S zip unzip make libtool flex   \
  mingw-w64-ucrt-x86_64-make            \
  mingw-w64-ucrt-x86_64-cmake           \
  mingw-w64-ucrt-x86_64-ccache          \
  mingw-w64-ucrt-x86_64-gcc-fortran     \
  mingw-w64-ucrt-x86_64-gcc-libs        \
  mingw-w64-ucrt-x86_64-binutils        \
  mingw-w64-ucrt-x86_64-curl            \
  mingw-w64-ucrt-x86_64-libiconv        \
  mingw-w64-ucrt-x86_64-readline        \
  mingw-w64-ucrt-x86_64-expat           \
  mingw-w64-ucrt-x86_64-libsystre       \
  mingw-w64-ucrt-x86_64-winpthreads-git \
  mingw-w64-ucrt-x86_64-opencl-headers  \
  mingw-w64-ucrt-x86_64-openblas
# Optional
pacman -S mingw-w64-ucrt-x86_64-qt5     \
  mingw-w64-ucrt-x86_64-qtwebkit        \
  mingw-w64-ucrt-x86_64-OpenSceneGraph  \
  mingw-w64-ucrt-x86_64-boost           \
  mingw-w64-ucrt-x86_64-python-numpy    \
  mingw-w64-ucrt-x86_64-libxml2         \
  mingw-w64-ucrt-x86_64-gdb             \
  mingw-w64-ucrt-x86_64-clang
```

## 1.3 Install Additional Programs

Install the following programs:

  - [Git](https://git-scm.com/downloads) (should already be installed)
  - [Java SE Development Kit](https://www.oracle.com/java/technologies/downloads/) (for javac)
  - [TortoiseSVN](https://tortoisesvn.net/), SVN tool for Windows
  - [CMake](https://cmake.org/download/) (>= v3.21)

## 1.4 Environment Variables

Start `C:\OMDev\tools\msys64\ucrt64.exe` and run:

```bash
# export the path to your tools: git, svn, java/javac
# note: if you have a space in your path to your tool you need to escape it, i.e.: /c/Program\ Files
export PATH=$PATH:/c/path/to/git/bin:/c/path/to/svn/tools/bin:/c/path/to/jdk/bin
export OPENMODELICAHOME="C:\\path\\to\\OpenModelica\\build"
export OPENMODELICALIBRARY="C:\\Users\\<user name>\\AppData\\Roaming\\.openmodelica\\libraries"
export OMDEV="C:\\OMDev"
```

You can add this to your `.bashrc` file
(usually in `C:\OMDev\tools\msys64\home\<USERNAME>\.bashrc`), to always have them in your
`PATH`.

Additional remarks:

  - MSYS doesn't use the Windows PATH variable.
    If you want to use it define a Windows environment variable called
    `MSYS2_PATH_TYPE=inherit`.
    But be very careful you don't have any MINGW directories in you Windows PATH, e.g.
    coming from Git.
  - MSYS doesn't use the Windows TEMP directory but `C:\OMDev\tools\msys64\tmp`
    You change this in `C:\OMDev\tools\msys64\etc\profile`, but it can have unexpected side effects.
  - If you want to use the msys shell from Windows command line  make sure you set
    environment variable `MSYSTEM=UCRT64` or call `C:\OMDev\tools\msys64\ucrt64.exe`.

# 2 Compile OpenModelica

You can use MSYS2 with environment UCRT64 with the Makefiles or CMake.
It's also possible to build with Eclipse using the Makefiles.
Follow the instructions in [MSYS and Make](#21-msys-and-make) or [Eclipse](#22-eclipse).

## 2.1 MSYS and CMake

Check [README.cmake.md](../README.cmake.md) for details, but in a nutshell start a MSYS2
shell `C:\OMDev\tools\msys64\ucrt64.exe` and run the following:

```bash
cd /path/to/OpenModelica
cmake -S . -B build_cmake -Wno-dev -G "MSYS Makefiles"
cd build_cmake
# Replace <Nr. of cores> with the number of your cores
make -j<Nr. of cores> install -Oline
```

## 2.2 MSYS and Make

Start MSYS terminal `C:\OMDev\tools\msys64\ucrt64.exe` and run:

```bash
cd /path/to/OpenModelica

# build omc using number of cores, replace by your number of cores
make -f Makefile.omdev.mingw -j<Nr. of cores>

# if you want to build only omedit then run:
make -f Makefile.omdev.mingw -j<Nr. of cores> omedit

# if you want to build all qtclients run
make -f Makefile.omdev.mingw -j<Nr. of cores> qtclients
```

# 3 Installer

To build the OpenModelica releases and installer the Makefiles build and NSIS is used.
If you need to know more checkout [OpenModelicaSetup/BuildWindowsRelease.sh](https://github.com/OpenModelica/OpenModelicaSetup#readme)


# 4 Test Suite

Many of the tests inside the test suite are OS dependent and will only work on a Linux OS.
Nonetheless you can run the test suite, but a lot of failing tests should be expected.

The test suite is only supported if you build using Makefiles. For CMake check
[README.cmake.md](../README.cmake.md).

Start your MSYS shell from OMDev and run:

```bash
make -f Makefile.omdev.mingw omc testsuite-depends -j<Nr. of cores>
cd testsuite/partests
./runtests.pl
```

# 5 Troubleshooting

If something does not work check the following:

1. Is OMDev removed?
   We switched from a shipped version of OMDev containing an outdated version of MSYS2
   with MINGW64 to a user installed version of MSYS2 with UCRT64 environment.
   They are not compatible. You need to re-configure and re-build everything. Throw in a
   git clean for good measure (be aware that this can remove everything that isn't
   committed...).

--------------

Last updated 2023-07-04.
