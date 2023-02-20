# Windows Instructions

## Table of content

- [1 OMDev Package](#1-omdev-package)
  - [1.1 General Notes](#11-general-notes)
  - [1.2 Install OMDev](#12-install-omdev)
  - [1.3 Install Additional Programs](#13-install-additional-programs)
  - [1.4 Environment Variables](#14-environment-variables)
- [2 Compile OpenModelica](#2-compile-openmodelica)
  - [2.1 MSYS and CMake](#21-msys-and-cmake)
  - [2.2 MSYS and Make](#22-msys-and-make)
- [3 Installer](#3-installer)
- [4 Test Suite](#4-test-suite)
- [5 Troubleshooting](#5-troubleshooting)

# 1 OMDev Package

We use Linux tools to compile OpenModelica on Windows. For that you'll need to install the
OMDev package contains all prerequisites to compile OMC on Windows using
msys2, mingw32 and mingw64.

## 1.1 General Notes

  - Install Git for Windows https://git-scm.com/downloads
  - Make sure you git clone with the correct line endings, run in a (Git Bash) terminal:
    ```bash
      git config --global core.eol lf
      git config --global core.autocrlf input
    ```

  - Do not install git using pacman in msys, it does not work correctly!

## 1.2 Install OMDev

  - Clone OMDev into a directory without any spaces in the path. We recommend to use
    `C:\OMDev\`.

    Run the following in a Git Bash:
    ```bash
      cd /c/
      git clone https://openmodelica.org/git/OMDev.git
    ```

  - Define a Windows environment variable `OMDEV` pointing to the OMDev directory.
    Restart or logiut/login to make it available.

  - Follow the instructions in the `C:\OMDev\INSTALL.txt` file.

If you encounter issues with OpenModelica compilation try updating OMDev (git pull).

## 1.3 Install Additional Programs

Install the following programms and add them to your MSYS `PATH`

  - Git (should alread be installed)
  - Java SE Development Kit (for javac)
  - TortoiseSVN, SVN tool for Windows

## 1.4 Environment Variables

Start `$OMDEV\tools\msys\mingw64.exe` or `$OMDEV\tools\msys\mingw32.exe` and run:

```bash
# export the path to your tools: git, svn, java/javac
# note: if you have a space in your path to your tool you need to escape it, i.e.: /c/Program\ Files
export PATH=$PATH:/c/path/to/git/bin:/c/path/to/svn/tools/bin:/c/path/to/jdk/bin
export OPENMODELICAHOME="c:\\path\\to\\OpenModelica\\build"
export OPENMODELICALIBRARY="c:\\path\\to\\OpenModelica\\build\\lib\\omlibrary"
```
You can add this to your `.bashrc` file
(usually in `C:\OMDev\tools\msys\home\<USERNAME>\.bashrc`), to always have them in your
`PATH`.

# 2 Compile OpenModelica

You can use msys2+mingw32 or msys2+mingw64 with the Makefiles or CMake.
It's also possible to build with Eclipse using the Makefiles.
Follow the instructions in [MSYS and Make](#21-msys-and-make) or [Eclipse](#22-eclipse).

## 2.1 MSYS and CMake

Check [README.cmake.md](../README.cmake.md) for details, but in a nutshell start a MSYS
shell `$OMDEV\tools\msys\mingw64.exe` and run the following:

```bash
cd /path/to/OpenModelica
cmake -S . -B build_cmake -Wno-dev -G "MSYS Makefiles"
cd build_cmake
# Replace <Nr. of cores> with the number of your cores
make -j<Nr. of cores> install -Oline
```

## 2.2 MSYS and Make

Start MSYS terminal `$OMDEV\tools\msys\mingw64.exe` (64 bit) or
`$OMDEV\tools\msys\mingw32.exe` (32 bit) and run:

```bash
cd /path/to/OpenModelica

# build omc using number of cores, replace by your number of cores
make -f Makefile.omdev.mingw -j<Nr. of cores>

# to build the QT clients make sure you ran \path\to\OMDEV\SETUP_OMDEV_Qt5.bat first

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

1. Is OMDev installed into `C:\OMDev`?
   - Be sure you have directories `tools`, `bin` and `include` in `C:\OMDev`.
   - Is environment variable `OMDEV` defined and pointing to it?
     Right Click on My Computer->Properties->Advanced Tab->Environment Variables.
     Add variable `OMDEV` and set the text to `C:\OMDev`.
     Restarted or logout/login from Windows to make it available.

For problems with OMDev package, contact Adrian Pop, adrian.pop@liu.se

--------------

Last updated 2023-02-13.
