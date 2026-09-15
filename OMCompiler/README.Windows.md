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
    - [2.2.1 Visual Studio](#221-visual-studio)
    - [2.2.2 Windows Terminal and Ninja](#222-windows-terminal-and-ninja)
    - [2.2.3 Enable Windows long path support](#223-enable-windows-long-path-support)
    - [2.2.4 vcpkg](#224-vcpkg)
    - [2.2.5 Configure and build omc](#225-configure-and-build-omc)
    - [2.2.6 Qt GUI clients](#226-qt-gui-clients)
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
- [rustup](https://rustup.rs) (optional if you disable it; see
  [1.4 Rust toolchain](#14-rust-toolchain) for which toolchain to pick and how to
  disable)

### 1.4 Rust toolchain

The C simulation runtime writes result files through the Rust `libomc_result`
(`OM_RUST_RESULT_WRITERS`) and the GUI clients read them back through it
(`OM_RUST_RESULT_READERS`). If disabled the C runtime falls back to the C
readers and writers, which cannot handle `.arrow`.

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

To build without Rust readers and writer at all:

```bash
cmake -S . -B build_cmake -Wno-dev -G "MSYS Makefiles" \
  -DOM_RUST_RESULT_READERS=OFF -DOM_RUST_RESULT_WRITERS=OFF
```

Two larger components are off by default: `-DOM_ENABLE_RUST_SIM_RUNTIME=ON` (the
runtime `--simCodeTarget=C+Rust` links, stable is enough) and
`-DOM_OMC_ENABLE_RUST=ON` (the compiler as the Rust port, needs the pinned
nightly in [Compiler/OpenModelica.rs/README.md](Compiler/OpenModelica.rs/README.md)).

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

You can compile the OpenModelica compiler (`omc`), the C simulation runtime, and the Qt GUI
clients (`OMEdit`, `OMPlot`, `OMShell`, `OMNotebook`) with the Microsoft Visual C++ compiler
(MSVC), and compile and simulate Modelica models with the result. Some parts are not built
with MSVC yet: the C++ simulation runtime, ModelicaExternalC, the OMSI runtimes, ParModelica
and PRIMME support, and FMU export.

There is a second, unrelated MSVC build that CI exercises: a cross-compile from Linux with
clang-cl, including the GUI clients built against Qt's MSVC kit. See
[Cross-compiling to Windows](Compiler/OpenModelica.rs/README.md#cross-compiling-to-windows-x86_64-pc-windows-msvc).
Everything below is about the **native** build, run directly on Windows.

This build does not use MSYS2. The dependencies (`libcurl`, `libiconv`, `gettext`,
`pthreads`, `Lapack`, ...) come from the Microsoft
[vcpkg](https://github.com/microsoft/vcpkg) package manager; Qt (for the GUI clients) comes
from an official prebuilt Qt instead (see [2.2.6](#226-qt-gui-clients)). All commands are run
in a Developer PowerShell for Visual Studio. If you use Rust, select the
`stable-x86_64-pc-windows-msvc` toolchain (see [1.4 Rust toolchain](#14-rust-toolchain)).

#### 2.2.1 Visual Studio

Any edition of **Visual Studio 2022 (v17) or newer** works, including **Community** and the
**Visual Studio 2026 (v18)** preview — the MSVC C++ ABI is stable across all of them, so a Qt
built for `msvc2022_64` links fine with a v18 compiler. The `msvc-ninja` CMake presets (see
[2.2.5](#225-configure-and-build-omc)) pick up whatever `cl.exe` is active in your Developer
shell; nothing is pinned to a specific toolset version.

Install the **"Desktop development with C++"** workload. It provides the MSVC compiler, the
Windows SDK, and — via the **"C++ CMake tools for Windows"** component — `cmake` and `ninja`.
The **Build Tools for Visual Studio** (no IDE) are enough if you only build from the command
line.

#### 2.2.2 Windows Terminal and Ninja

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

#### 2.2.3 Enable Windows long path support

Some packages built by vcpkg (and some deep vcpkg/Ninja build-tree paths) exceed Windows's
default 260-character path limit, which fails the build. Before proceeding, enable long path
support by following the Microsoft documentation:
[Enable long paths in Windows](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry).

#### 2.2.4 vcpkg

Clone vcpkg at the root of OpenModelica. It works as a local package manager: packages are
installed into the CMake build directory, leaving the rest of your system unaffected
(except for some temporary files and caches in your TEMP folder).

```powershell
cd OpenModelica
git clone https://github.com/microsoft/vcpkg.git
```

The `vcpkg.json` manifest at the repository root already lists the required packages; vcpkg
installs them in [manifest mode](https://learn.microsoft.com/en-us/vcpkg/concepts/manifest-mode)
the first time you configure (see [2.2.5](#225-configure-and-build-omc)) — nothing to create
yourself.

#### 2.2.5 Configure and build omc

The repository includes a `CMakePresets.json` file that captures the full MSVC build
configuration. The preset named `msvc-ninja` selects the Ninja generator, the MSVC compiler,
vcpkg, and the appropriate feature flags (it also disables parts not built with MSVC yet:
Fortran/optimization/MOO, ColPack, the Rust result readers/writers).

Open a Developer PowerShell for Visual Studio and run:

```powershell
cd OpenModelica
cmake --preset msvc-ninja
cmake --build --preset msvc-ninja
```

The first build takes a considerable amount of time: vcpkg bootstraps itself, downloads,
builds and installs all packages listed in `vcpkg.json` (using prebuilt binaries where
available), and only then CMake builds OpenModelica. Later builds are faster, since vcpkg
does nothing unless `vcpkg.json` changes.

The build preset targets `install` by default, so CMake installs OpenModelica into
`build\msvc-ninja\install_cmake\`. Check that `omc` works and can simulate a model:

```powershell
.\build\msvc-ninja\install_cmake\bin\omc.exe --help

@'
loadString("model M Real x(start=1); equation der(x)=-x; end M;");
simulate(M, stopTime=1.0);
getErrorString();
'@ | Set-Content t.mos
.\build\msvc-ninja\install_cmake\bin\omc.exe t.mos
```

The `simulate(M, ...)` call should return a `SimulationResult` record with a non-empty
`resultFile` and empty `messages`.

#### 2.2.6 Qt GUI clients

The GUI clients need Qt 6. Building Qt (and especially `QtWebEngine`, which `OMEdit` uses)
from source takes hours, so instead point the build at an **official prebuilt Qt for MSVC**.
vcpkg still provides the C libraries; Qt is found through `CMAKE_PREFIX_PATH` and is not added
to `vcpkg.json`.

Install an official prebuilt **Qt 6 for MSVC 2022 64-bit**, ideally the same Qt 6 minor
version the MSYS2/UCRT64 build uses (Qt 6.11.2 is a good current choice). The installer does
**not** resolve module dependencies for you, so tick **all** of these components under the Qt
version:

| Installer component | `find_package` components it provides |
|---|---|
| **MSVC 2022 64-bit** | `Widgets` `Gui` `Core` `Network` `OpenGL` `OpenGLWidgets` `PrintSupport` `Xml` `Svg` `Test` `LinguistTools` `Quick` `Qml` `QuickWidgets`, plus `windeployqt` |
| **Qt 5 Compatibility Module** | `Core5Compat` |
| **Qt WebEngine** | `WebEngineWidgets` (used by `OMEdit`) |
| **Qt WebChannel** | dependency of Qt WebEngine |
| **Qt Positioning** | dependency of Qt WebEngine |
| **Qt Quick 3D** | `Quick3D` — OMEdit's animation backend (`OM_OMEDIT_ANIMATION_QUICK3D=ON`) |

`Qt HTTP Server` is used if present but is optional. Miss **Qt WebChannel** / **Qt
Positioning** and `find_package(Qt6 WebEngineWidgets)` fails with *"dependency
Qt6WebEngineCore could not be found"*.

> [!NOTE]
> Using the Qt Quick 3D animation backend means **OpenSceneGraph is not required** (it is the
> other backend, and there is no vcpkg/prebuilt path set up for it here). The only remaining
> non-Qt prerequisite is a Java runtime, which OpenModelica already needs.

Get Qt either from the GUI [online installer](https://www.qt.io/download-qt-installer) (needs
a free Qt account; installs into e.g. `C:\Qt\6.11.2\msvc2022_64`), or with
[`aqtinstall`](https://github.com/miurahr/aqtinstall) (no sign-in, pulls the same official
prebuilt archives):

```powershell
pip install aqtinstall
aqt install-qt windows desktop 6.11.2 win64_msvc2022_64 -m qt5compat qtwebengine qtwebchannel qtpositioning qtquick3d --outputdir C:\Qt
```

Then tell CMake where Qt is with `QT_ROOT_DIR` (the `msvc2022_64` directory) and use the
`msvc-ninja-gui` preset (`msvc-ninja` plus `OM_ENABLE_GUI_CLIENTS=ON` and
`OM_OMEDIT_ANIMATION_QUICK3D=ON`):

```powershell
$env:QT_ROOT_DIR = "C:\Qt\6.11.2\msvc2022_64"
cmake --preset msvc-ninja-gui
cmake --build --preset msvc-ninja-gui
```

On `install`, `windeployqt` copies the Qt runtime (DLLs, plugins, translations, and the
QtWebEngine assets for `OMEdit`) next to each `.exe`; the non-Qt DLLs come from vcpkg. The
clients end up in `build\msvc-ninja-gui\install_cmake\bin\`:

```powershell
.\build\msvc-ninja-gui\install_cmake\bin\OMEdit.exe
```

> [!NOTE]
> The legacy `OMShell` REPL terminal (`mosh`) needs GNU readline, which is not available for
> MSVC, so it is disabled by default here (`OM_OMSHELL_ENABLE_TERMINAL=OFF`); the `OMShell`
> GUI is still built.

## 3 Installer

To build the OpenModelica releases and installer NSIS is used.
If you need to know more checkout
[OpenModelicaSetup/BuildWindowsRelease.sh](https://github.com/OpenModelica/OpenModelicaSetup#readme)

## 4 Test Suite

Many of the tests inside the test suite are OS dependent and will only work on a Linux OS.
Nonetheless you can run the test suite, but a lot of failing tests should be expected.

Start your MSYS shell from OMDev and follow
[6. Running Tests](../README.cmake.md#6-running-tests) in README.cmake.md.
