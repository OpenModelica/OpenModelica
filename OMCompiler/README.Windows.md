# Windows Instructions

## Table of content

- [1 MSYS Environments](#1-msys-environments)
  - [1.1 General Notes](#11-general-notes)
  - [1.2 Install OMDev packages](#12-install-omdev)
  - [1.3 Install MSYS2](#13-install-msys2)
  - [1.4 Install Additional Programs](#14-install-additional-programs)
  - [1.5 Environment Variables](#15-environment-variables)
- [2 Compile OpenModelica](#2-compile-openmodelica)
  - [2.1 MSYS and CMake](#21-msys-and-cmake)
  - [2.2 MSYS and Make](#22-msys-and-make)
- [3 Installer](#3-installer)
- [4 Test Suite](#4-test-suite)
- [5 Troubleshooting](#5-troubleshooting)

# 1 MSYS Environments

We use Linux tools provided by [MSYS2](https://www.msys2.org/) to compile OpenModelica on
Windows.

You can install MSYS2 with UCRT64 yourself or use OMDev with an MSYS2 installation and
fixed package versions. If you are unsure what to pick or are building OpenModelica for
the first time use OMDev.

> [!NOTE]
> If you have an older version of OMDev installed it's best to delete `OMDev` and start
> with a fresh clone following the below instructions.

  1. OMDev package: MSYS2 with
    [UCRT64 environment](https://www.msys2.org/docs/environments/).
    Follow the instructions in [1.2 Install OMDev](#12-install-omdev).
  2. Installed [MSYS2](https://www.msys2.org/) with
    [UCRT64 environment](https://www.msys2.org/docs/environments/).
    Follow the instructions in [1.3 Install MSYS2](#13-install-msys2).


## 1.1 General Notes

  - Install Git for Windows https://git-scm.com/downloads
    Do not install git using pacman in MSYS, it does not work correctly!
  - Make sure you git clone with the correct line endings, run in a (Git Bash) terminal:
    ```bash
      git config --global core.eol lf
      git config --global core.autocrlf input
    ```

## 1.2 Install OMDev

  - Clone OMDev into a directory without any spaces in the path. We recommend to use
    `C:\OMDev\`.

    Run the following in a Git Bash:
    ```bash
      cd /c/
      git clone --depth 1 -b master --single-branch https://gitlab.liu.se/OpenModelica/OMDevUCRT.git OMDev
    ```

  - Define a Windows environment variable `OMDEV` pointing to the OMDev directory.
    Restart or logout/login to make it available.

  - Follow the instructions in the `%OMDEV%\INSTALL.md` file.

## 1.4 Install Additional Programs

Install the following programs:

  - [Git](https://git-scm.com/downloads) (should already be installed)
  - [Java SE Development Kit](https://www.oracle.com/java/technologies/downloads/) (for javac)
  - [TortoiseSVN](https://tortoisesvn.net/), SVN tool for Windows
  - [CMake](https://cmake.org/download/) (>= v3.21)

## 1.5 Environment Variables

Export the path to your tools: git, svn, java/javac and cmake.
Define environment variables pointing to your OMDev directory as well as the MSYS2
root directory.

> [!NOTE]
> Use Linux like path. E.g. `C:\Program Files\Git\bin` becomes `/c/Program Files/Git/bin`

```bash
export PATH=$PATH:/c/path/to/git/bin:/c/path/to/svn/tools/bin:/c/path/to/jdk/bin:/c/path/to/cmake/bin
export OPENMODELICAHOME="/c/path/to/OpenModelica/build"
export OPENMODELICALIBRARY="/c/Users/<user name>/AppData/Roaming/.openmodelica/libraries"
export OMDEV="/c/OMDev"
export OMDEV_MSYS="/c/OMDev/tools/msys"
```

You can add this to your `.bashrc` file
(usually in `%OMDEV%\tools\msys\home\<USERNAME>\.bashrc`), to always have them in your
`PATH`.

Additional remarks:

  - MSYS doesn't use the Windows PATH variable.
    If you want to use it define a Windows environment variable called
    `MSYS2_PATH_TYPE=inherit`.
    But be very careful you don't have any MINGW directories in you Windows PATH, e.g.
    coming from Git.
  - MSYS doesn't use the Windows TEMP directory but `C:\OMDev\tools\msys\tmp`
    You change this in `C:\OMDev\tools\msys\etc\profile`, but it can have unexpected side effects.
  - If you want to use the msys shell from Windows command line  make sure you set
    environment variable `MSYSTEM=UCRT64` or call `C:\OMDev\tools\msys\ucrt64.exe`.

# 2 Compile OpenModelica

You can use MSYS2 with environment UCRT64 with the Makefiles or CMake.
It's also possible to build with Eclipse using the Makefiles.
Follow the instructions in [MSYS and Make](#21-msys-and-make) or [Eclipse](#22-eclipse).

## 2.1 MSYS and CMake

Check [README.cmake.md](../README.cmake.md) for details, but in a nutshell start a MSYS2
shell `C:\OMDev\tools\msys\ucrt64.exe` (UCRT64) or `C:\OMDev\tools\msys\mingw64.exe`
(MINGW64) and run the following:

```bash
cd /path/to/OpenModelica
cmake -S . -B build_cmake -Wno-dev -G "MSYS Makefiles"
cd build_cmake
# Replace <Nr. of cores> with the number of your cores
make -j<Nr. of cores> install -Oline
```

## 2.2 MSYS and Make

Start `C:\OMDev\tools\msys\ucrt64.exe` (UCRT64) or `C:\OMDev\tools\msys\mingw64.exe`
(MINGW64) and run:

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
If you need to know more checkout
[OpenModelicaSetup/BuildWindowsRelease.sh](https://github.com/OpenModelica/OpenModelicaSetup#readme)


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

Last updated 2023-08-11.
