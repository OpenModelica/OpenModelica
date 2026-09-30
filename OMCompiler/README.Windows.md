# Windows Instructions

## Table of content

- [1 MSYS Environments](#1-msys-environments)
  - [1.1 General Notes](#11-general-notes)
  - [1.2 Install OMDev packages](#12-install-omdev)
  - [1.3 Install Additional Programs](#13-install-additional-programs)
  - [1.4 Rust toolchain](#14-rust-toolchain)
  - [1.5 Environment Variables](#15-environment-variables)
- [2 Compile OpenModelica](#2-compile-openmodelica)
  - [2.1 MSYS and CMake](#21-msys-and-cmake)
  - [2.2 MSVC (experimental)](#22-msvc-experimental)
- [3 Installer](#3-installer)
- [4 Test Suite](#4-test-suite)

## 1 MSYS Environments

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
  You need to install all necessary packages yourself.

### 1.1 General Notes

- Install Git for Windows [git-scm.com](https://git-scm.com/downloads)

  > [!CAUTION]
  > Do not install git using pacman in MSYS, it does not work correctly!

- Make sure you git clone with the correct line endings, run in a (Git Bash) terminal:

  ```bash
    git config --global core.eol lf
    git config --global core.autocrlf input
  ```

### 1.2 Install OMDev

- Clone OMDev into a directory without any spaces in the path.
  We recommend to use `C:\OMDev\`.

  Run the following in a Git Bash:

  ```bash
    cd /c/
    git clone --depth 1 -b master --single-branch https://gitlab.liu.se/OpenModelica/OMDevUCRT.git OMDev
  ```

- Define a Windows environment variable `OMDEV` pointing to the OMDev directory.
  Restart or logout/login to make it available.

- Follow the instructions in the `%OMDEV%\INSTALL.md` file.

### 1.3 Install Additional Programs

Install the following programs:

- [Git](https://git-scm.com/downloads) (should already be installed)
- [Java SE Development Kit](https://www.oracle.com/java/technologies/downloads/) (for javac)
- [CMake](https://cmake.org/download/) (>= v3.21)
- [rustup](https://rustup.rs) (see [1.4 Rust toolchain](#14-rust-toolchain) for
  which toolchain to pick)

### 1.4 Rust toolchain

Result files are read and written through the Rust `libomc_result`, and
`--simCodeTarget=C` links the Rust simulation runtime.

The crates use the 2024 edition, so `cargo`/`rustc` 1.85 or newer. Install
[rustup](https://rustup.rs) from Windows (not through pacman), with
`winget install Rustlang.Rustup` or `rustup-init.exe`.

> [!NOTE]
> MSYS only sees it if you set `MSYS2_PATH_TYPE=inherit` (see
> [1.5 Environment Variables](#15-environment-variables)) or add
> `%USERPROFILE%\.cargo\bin` to the `PATH` inside the shell.

The Rust library is linked into the C/C++ binaries, so the ABIs have to match.
`rustup` installs the **MSVC** toolchain by default, so an OMDev build has to
install and select the GNU one:

| Building with          | Toolchain to select             |
|------------------------|---------------------------------|
| OMDev / MSYS2 (UCRT64) | `stable-x86_64-pc-windows-gnu`  |
| MSVC                   | `stable-x86_64-pc-windows-msvc` |

```bash
cd /path/to/OpenModelica   # override set applies to this directory only
rustup toolchain install stable-x86_64-pc-windows-gnu
rustup override set stable-x86_64-pc-windows-gnu
cargo -vV   # the host: line must end in -gnu here, -msvc for MSVC
```

`-DOM_OMC_ENABLE_RUST=ON` (the compiler as the Rust port, off by default) needs
the pinned nightly in [Compiler/OpenModelica.rs/README.md](Compiler/OpenModelica.rs/README.md).

### 1.5 Environment Variables

Export the path to your tools: git, java/javac and cmake.
Define environment variables pointing to your OMDev directory as well as the MSYS2
root directory.

> [!NOTE]
> Use Linux like path. E.g. `C:\Program Files\Git\bin` becomes `/c/Program Files/Git/bin`

```bash
export PATH="$PATH:/c/path/to/git/bin:/c/path/to/jdk/bin:/c/path/to/cmake/bin"
export OPENMODELICAHOME="/c/path/to/OpenModelica/build_cmake/install_cmake"
export OPENMODELICALIBRARY="/c/Users/<user name>/AppData/Roaming/.openmodelica/libraries"
export OMDEV="/c/OMDev"
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

## 2 Compile OpenModelica

On Windows, CMake is the only supported way to build OpenModelica. The supported toolchain
is MSYS2 with UCRT64, see [2.1 MSYS and CMake](#21-msys-and-cmake). Building with MSVC is
experimental, see [2.2 MSVC (experimental)](#22-msvc-experimental).

### 2.1 MSYS and CMake

Check [README.cmake.md](../README.cmake.md) for details, but in a nutshell start a MSYS2
shell `C:\OMDev\tools\msys\ucrt64.exe` (UCRT64) or `C:\OMDev\tools\msys\mingw64.exe`
(MINGW64) and run the following:

```bash
cd /path/to/OpenModelica
cmake -S . -B build_cmake -Wno-dev -G "MSYS Makefiles"
cd build_cmake
# Replace <Nr. of cores> with the number of your cores
make -j<Nr. of cores> install -Oline

# Default install dir is a directory named install_cmake inside the build directory.
./install_cmake/bin/omc --help
```

The generator has to be "MSYS Makefiles". This is not what CMake chooses by default on
Windows.

> [!NOTE]
> `-Oline` instructs GNU Make to print outputs one line at a time, making sure ANSI color
> codes do not get interleaved. With `-Oline` added, a Makefile step is printed once it is
> **completed**, not when it is issued. So if you see something taking a long time, it is
> probably the thing that is printed right after which is actually the culprit.

### 2.2 MSVC (experimental)

> [!WARNING]
> The OpenModelica MSVC build is highly experimental. If you encounter issues or have
> suggestions for fixes please open a new discussion or issue.

You can compile the OpenModelica compiler (`omc`) and the C and C++ simulation runtimes
with the Microsoft Visual C++ compiler (MSVC). Some parts are not built with MSVC yet:
ModelicaExternalC, the OMSI runtimes, ParModelica and PRIMME support. Compiling and
simulating models with such a build may still need some work.

The MSVC build that CI exercises is a cross-compile from Linux with clang-cl, including the
GUI clients built against Qt's MSVC kit. See
[Cross-compiling to Windows](Compiler/OpenModelica.rs/README.md#cross-compiling-to-windows-x86_64-pc-windows-msvc).
The native build described here does not cover the GUI clients.

This build does not use MSYS2. The dependencies (`libcurl`, `libiconv`, `gettext`,
`pthreads`, `Lapack`, `Boost`, ...) come from the Microsoft
[vcpkg](https://github.com/microsoft/vcpkg) package manager, and all commands are run in a
Developer PowerShell for Visual Studio. If you use Rust, select the
`stable-x86_64-pc-windows-msvc` toolchain (see [1.4 Rust toolchain](#14-rust-toolchain)).

#### 2.2.1 Windows Terminal and Ninja

We recommend Windows Terminal. It is included in Windows 11; on Windows 10 install it from
the [Microsoft Store](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701).
It detects the Developer PowerShell and Developer Command Prompt for Visual Studio
automatically, so you can open them from its list of shells.

These instructions use the [Ninja](https://ninja-build.org/) generator. Recent Visual Studio
versions ship it with the `C++ CMake tools for Windows` installation component. Check that
it is available from a Developer PowerShell for Visual Studio:

```powershell
Get-Command ninja.exe
```

> [!WARNING]
> In a normal PowerShell or CMD terminal the Visual Studio tools might not be available.
> Refer to the Microsoft
> [documentation](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line)
> for more info.

If Ninja is missing, download the binary from the
[Ninja GitHub repository](https://github.com/ninja-build/ninja/releases) and put it in the
`CMake\bin\` directory (e.g., `C:\Program Files\CMake\bin`), so it is available wherever
CMake is. You can use another generator, but then adjust the CMake commands below.

#### 2.2.2 vcpkg

Clone vcpkg at the root of OpenModelica. It works as a local package manager: packages are
installed into the CMake build directory, leaving the rest of your system unaffected
(except for some temporary files and caches in your TEMP folder).

```powershell
cd OpenModelica
git clone https://github.com/microsoft/vcpkg.git
```

Then create a file named `vcpkg.json` in the OpenModelica directory with the following
contents. It tells vcpkg which packages to install in
[manifest mode](https://learn.microsoft.com/en-us/vcpkg/concepts/manifest-mode).

```json
{
  "name": "openmodelica",
  "homepage": "https://openmodelica.org/",
  "description": "an open-source Modelica-based modeling and simulation environment intended for industrial and academic usage.",
  "dependencies": [
    "curl",
    "libiconv",
    "gettext",
    "lapack",
    "pthread",
    "dirent",
    "boost-program-options",
    "boost-filesystem",
    "boost-ublas",
    "boost-lambda",
    "boost-asio",
    "boost-circular-buffer"
  ]
}
```

The Boost packages are for the C++ simulation runtime. Instead of getting Boost from vcpkg,
`-DOM_FETCH_BOOST=ON` downloads and builds it as part of OpenModelica; that option is meant
for cross builds and has not been tested with a native MSVC build.

> [!NOTE]
> This file might eventually become part of the OpenModelica repository. Until the MSVC
> build is tested well, create it locally.

#### 2.2.3 Configure and build

Setting `OM_WITH_VCPKG=ON` tells CMake to take the packages from vcpkg. Open a Developer
PowerShell for Visual Studio and run:

```powershell
cd OpenModelica
cmake -S . -B build_msvc_ninja -Wno-dev -DOM_WITH_VCPKG=ON -DOM_USE_CCACHE=OFF -DOM_ENABLE_GUI_CLIENTS=OFF -DOM_OMC_ENABLE_FORTRAN=OFF -DOM_OMC_ENABLE_OPTIMIZATION=OFF -DOM_OMC_ENABLE_MOO=OFF -G "Ninja"
cmake --build build_msvc_ninja --target install
```

The options:

- `OM_WITH_VCPKG=ON` uses the packages installed by vcpkg.
- `OM_USE_CCACHE=OFF`, since ccache is not installed and does not work well with MSVC.
- `OM_ENABLE_GUI_CLIENTS=OFF`, since the native MSVC build does not cover the GUI clients.
- `OM_OMC_ENABLE_FORTRAN=OFF`, since there is no Fortran compiler. The dynamic optimization
  runtimes need Fortran, so `OM_OMC_ENABLE_OPTIMIZATION` and `OM_OMC_ENABLE_MOO` are
  disabled as well.

The first build takes a considerable amount of time: vcpkg bootstraps itself, then
downloads, builds and installs all packages listed in `vcpkg.json` (using prebuilt binaries
where available), and only then CMake builds OpenModelica. Later builds are faster, since
vcpkg does nothing unless `vcpkg.json` changes.

CMake installs OpenModelica into `OpenModelica/build_msvc_ninja/install_cmake/`. Check that
`omc` works:

```powershell
.\build_msvc_ninja\install_cmake\bin\omc.exe --help
```

If this prints the omc help, omc can be used to generate model code. Compiling the generated
model code and simulating models still needs some fixes.

## 3 Installer

To build the OpenModelica releases and installer NSIS is used.
If you need to know more checkout
[OpenModelicaSetup/BuildWindowsRelease.sh](https://github.com/OpenModelica/OpenModelicaSetup#readme)

## 4 Test Suite

Many of the tests inside the test suite are OS dependent and will only work on a Linux OS.
Nonetheless you can run the test suite, but a lot of failing tests should be expected.

Start your MSYS shell from OMDev and follow
[6. Running Tests](../README.cmake.md#6-running-tests) in README.cmake.md.
