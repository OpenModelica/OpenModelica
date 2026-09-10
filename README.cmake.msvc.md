# OpenModelica CMake build instructions for MSVC

- [1. Introduction](#1-introduction)
- [2. Setup `Windows Terminal`](#2-setup-windows-terminal)
- [3. Setup `Ninja Build`](#3-setup-ninja-build)
- [4. Enable Windows Long Path Support](#4-enable-windows-long-path-support)
- [5. Setup the `vcpkg` package manager](#5-setup-the-vcpkg-package-manager)
- [6. Configure OpenModelica](#6-configure-openmodelica)
- [7. Build OpenModelica](#7-build-openmodelica)
- [8. Build the Qt GUI clients (OMEdit, OMPlot, OMShell, OMNotebook)](#8-build-the-qt-gui-clients-omedit-omplot-omshell-omnotebook)


# 1. Introduction

> **Warning**
> The OpenModelica MSVC build is highly experimental.
> If you encounter issues or have suggestions of fixes please open a new discussion or issue.

It is possible, albeit a bit complicated, to compile some of the OpenModelica tools with the **Microsoft Visual Studio Compiler** (**MSVC**).
Specifically, you can compile the OpenModelica Modelica compiler itself (`omc`) and almost all libraries needed for simulation of a Modelica model.
However, running actual simulations still needs some work.

The Qt GUI clients (`OMEdit`, `OMPlot`, `OMShell`, `OMNotebook`) can also be built, against an
official prebuilt Qt 6 for MSVC — see [section 8](#8-build-the-qt-gui-clients-omedit-omplot-omshell-omnotebook).
Qt is **not** built from source and is **not** a vcpkg dependency.

On Windows, a package manager is necessary to get all the ubiquitous Linux libraries that we have come to depend on such as `libcurl`, `libiconv`, `gettext` and `pthreads`.
In addition, we also need to make available the bigger dependencies starting from `Lapack` all the way to `Boost`.

## Visual Studio

Any edition of **Visual Studio 2022 (v17) or newer** works, including **Community** and the
**Visual Studio 2026 (v18)** preview — the MSVC C++ ABI is stable across all of them, so a Qt built
for `msvc2022_64` links fine with a v18 compiler. The `msvc-ninja` presets pick up whatever `cl.exe`
is active in your Developer shell; nothing is pinned to a specific toolset version.

Install the **"Desktop development with C++"** workload. It provides the MSVC compiler, the Windows
SDK, and — via the **"C++ CMake tools for Windows"** component — `cmake` and `ninja`. The
**Build Tools for Visual Studio** (no IDE) are enough if you only build from the command line.

These instructions are intended to be used with:
- The `Windows Terminal` terminal.
- The `Ninja Build` build tool.
- The Microsoft `vcpkg` package manager.

You can probably follow these instructions without using the first two tools above if you know what you are doing.
However, forgoing `vcpkg` is not possible without a lot of extra work.
It is recommended to use these tools at least as an initial step since those tools are where these instructions are tested on.

# 2. Setup `Windows Terminal`

If you do not have it already, **it is highly recommended to install and use** [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=sv-se&gl=se) from the Microsoft Store.
You can also install it [manually](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=sv-se&gl=se) if you prefer.
This terminal is much superior and configurable than the default Windows CMD terminal.
It will also detect and set up shells like Developer PowerShell and CMD for Visual Studio automatically which should make things easier going forward.

# 3. Setup `Ninja Build`

These instructions are also for the [Ninja](https://ninja-build.org/) build tool.
Ninja is chosen because it is portable across Windows, Linux and macOS.
It is also straightforward to perform parallelized builds with `Ninja` (in fact it is the default behavior).
In addition, it is the closest tool to GNU Make compared to MSBuild or NMake, which should make it easier to follow for those coming from the `Linux`, `macOS`, and the `GNU Make` ecosystems.
That said, you can use your preferred generator and adjust the CMake commands in this document accordingly.

Recent Visual Studio versions should come with `Ninja` by default in the `C++ CMake tools for Windows` installation component.
You can check the existence of Ninja on your system by launching a Developer PowerShell for Visual Studio and running the command

> **Note**
> If you have installed the Windows Terminal app (see [2. Setup Windows Terminal](#2-setup-windows-terminal)), then the Developer PowerShell For Visual Studio will be available in the consoles list and you can just open it from there and proceed.

```powershell
Get-Command ninja.exe
```

> **Warning**
> If you want to use a normal PowerShell or CMD terminal, make sure you make the Visual Studio tools available as they might not be available by default.
> Refer to the Microsoft [documentation](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170) for more info.


If you do not have Ninja available, you can just download the binary from [Ninja Github Repository](https://github.com/ninja-build/ninja/releases) and put it in the `CMake\bin\` directory (e.g., `C:\Program Files\CMake\bin`) to make sure it is available wherever CMake is available.


# 4. Enable Windows Long Path Support

Some packages built by vcpkg generate file paths that exceed Windows's default 260-character limit, which will cause the build to fail.
Before proceeding, enable long path support by following the instructions in the Microsoft documentation:
[Enable long paths in Windows](https://learn.microsoft.com/en-us/windows/win32/fileio/maximum-file-path-limitation?tabs=registry).

# 5. Setup the `vcpkg` package manager

The next thing to do is to clone the vcpkg repo at the root of OpenModelica.
This will be set up as a local package manager which will install packages only for the current project leaving the rest of your system completely unaffected (except for some temporary files and cache in your TEMP folders).
**It will install all packages under the CMake build directory** that you specify.

```sh
cd OpenModelica
git clone https://github.com/microsoft/vcpkg.git
```

The `vcpkg.json` manifest file listing the required packages is already included in the repository.
It tells vcpkg which packages to install in [manifest mode](https://learn.microsoft.com/en-us/vcpkg/users/manifests) — think of it as a `package.json` for Node.js.

# 6. Configure OpenModelica

The repository includes a `CMakePresets.json` file that captures the full MSVC build configuration.
The preset named `msvc-ninja` selects the Ninja generator, the MSVC compiler, vcpkg, and the appropriate feature flags.

Open a **Developer PowerShell For Visual Studio** terminal and run:

```powershell
cd OpenModelica
cmake --preset msvc-ninja
```

This places the build tree under `build/msvc-ninja/` and the install tree under `build/msvc-ninja/install_cmake/`.

# 7. Build OpenModelica

If configuration finished successfully, proceed to building OpenModelica:

```powershell
cmake --build --preset msvc-ninja
```

The build preset targets `install` by default, so this is equivalent to:

```powershell
cmake --build build/msvc-ninja --target install
```

The first build will take a considerable amount of time because:

- `vcpkg` will bootstrap itself (downloads or builds the vcpkg executable).
- `vcpkg` will download, build, and locally install all packages listed in `vcpkg.json`.
  This can take several minutes — monitor the progress.
- Once packages are ready, CMake will build OpenModelica itself.

> **Note**
> Subsequent builds are much faster: vcpkg does nothing unless `vcpkg.json` is modified.

If the build completed successfully, CMake will have installed the project into `build/msvc-ninja/install_cmake/`.

Check that `omc` is installed and working:

```powershell
.\build\msvc-ninja\install_cmake\bin\omc.exe --help
```

If this prints the omc help text, the compiler is built correctly and can be used to generate model code.
Actually compiling the generated model code and running simulations still needs some work.

# 8. Build the Qt GUI clients (OMEdit, OMPlot, OMShell, OMNotebook)

The GUI clients need Qt 6. Building Qt (and especially `QtWebEngine`, which `OMEdit` uses) from
source takes hours, so instead point the build at an **official prebuilt Qt for MSVC**. vcpkg still
provides the C libraries; Qt is found through `CMAKE_PREFIX_PATH` and is not added to `vcpkg.json`.

## 8.1 Install Qt

Install an official prebuilt **Qt 6 for MSVC 2022 64-bit**, ideally the same Qt 6 minor version the
MSYS2/UCRT64 build uses (Qt 6.11.2 is a good current choice). The installer does **not** resolve
module dependencies for you, so tick **all** of these components under the Qt version:

| Installer component | `find_package` components it provides |
|---|---|
| **MSVC 2022 64-bit** | `Widgets` `Gui` `Core` `Network` `OpenGL` `OpenGLWidgets` `PrintSupport` `Xml` `Svg` `Test` `LinguistTools` `Quick` `Qml` `QuickWidgets`, plus `windeployqt` |
| **Qt 5 Compatibility Module** | `Core5Compat` |
| **Qt WebEngine** | `WebEngineWidgets` (used by `OMEdit`) |
| **Qt WebChannel** | dependency of Qt WebEngine |
| **Qt Positioning** | dependency of Qt WebEngine |
| **Qt Quick 3D** | `Quick3D` — OMEdit's animation backend (`OM_OMEDIT_ANIMATION_QUICK3D=ON`) |

`Qt HTTP Server` is used if present but is optional. Miss **Qt WebChannel** / **Qt Positioning** and
`find_package(Qt6 WebEngineWidgets)` fails with *"dependency Qt6WebEngineCore could not be found"*.

> Using the Qt Quick 3D animation backend means **OpenSceneGraph is not required** (it is the other
> backend, and there is no vcpkg/prebuilt path set up for it here). The only remaining non-Qt
> prerequisite is a Java runtime, which OpenModelica already needs.

### Option A — GUI installer

Download `qt-online-installer-windows-x64-<version>.exe` from
<https://www.qt.io/download-qt-installer>. It needs a **free Qt account** (there is no open-source
offline installer for Qt 6). Run it, sign in, expand your Qt version and tick every component
from the table above.

The installer also has a scriptable
[command line interface](https://doc.qt.io/qt-6.8/get-and-install-qt-cli.html) — pass the `install`
subcommand (running it with no arguments just opens the GUI):

```powershell
$installer = "qt-online-installer-windows-x64.exe"

# One-off: sign in (stores credentials for later runs). Or pass --email / --pw on each call.
& $installer --accept-licenses --accept-obligations --default-answer login

# Install Qt 6.11.2 for MSVC 2022 64-bit + every module OMEdit needs. The installer
# does NOT pull module dependencies, so list qtwebchannel/qtpositioning explicitly.
& $installer `
    --root C:\Qt `
    --accept-licenses --accept-obligations --default-answer --confirm-command `
    install `
      qt.qt6.6112.win64_msvc2022_64 `
      qt.qt6.6112.qt5compat `
      qt.qt6.6112.addons.qtwebengine `
      qt.qt6.6112.addons.qtwebchannel `
      qt.qt6.6112.addons.qtpositioning `
      qt.qt6.6112.addons.qtquick3d
```

The package id encodes the version without dots: Qt 6.11.2 → `qt.qt6.6112.*`. `search "qt.qt6.*"` lists
the exact ids. This installs into `C:\Qt\6.11.2\msvc2022_64`.

To add the modules to an existing Qt install instead, run `C:\Qt\MaintenanceTool.exe` (GUI:
*Add or remove components*) or `MaintenanceTool.exe --accept-licenses --default-answer --confirm-command
install qt.qt6.6112.addons.qtwebchannel qt.qt6.6112.addons.qtpositioning qt.qt6.6112.addons.qtquick3d`.

### Option B — aqtinstall (no Qt account)

[`aqtinstall`](https://github.com/miurahr/aqtinstall) is an unofficial installer that pulls the
**same official prebuilt archives** straight from Qt's download servers, with no sign-in:

```powershell
pip install aqtinstall
aqt install-qt windows desktop 6.11.2 win64_msvc2022_64 -m qt5compat qtwebengine qtwebchannel qtpositioning qtquick3d --outputdir C:\Qt
```

This installs into `C:\Qt\6.11.2\msvc2022_64`. `aqt list-qt windows desktop --arch 6.11.2` shows the
available architectures and `... --modules 6.11.2 win64_msvc2022_64` the available module names.

## 8.2 Configure with the GUI preset

Tell CMake where Qt is by setting `QT_ROOT_DIR` to the Qt prefix (the `msvc2022_64` directory), then
use the `msvc-ninja-gui` preset (`msvc-ninja` plus `OM_ENABLE_GUI_CLIENTS=ON` and
`OM_OMEDIT_ANIMATION_QUICK3D=ON`):

```powershell
$env:QT_ROOT_DIR = "C:\Qt\6.11.2\msvc2022_64"
cmake --preset msvc-ninja-gui
```

Alternatively pass the path directly: `cmake --preset msvc-ninja-gui -DCMAKE_PREFIX_PATH=C:/Qt/6.11.2/msvc2022_64`.

## 8.3 Build

```powershell
cmake --build --preset msvc-ninja-gui
```

On `install`, `windeployqt` copies the Qt runtime (DLLs, plugins, translations, and the QtWebEngine
assets for `OMEdit`) next to each `.exe`; the non-Qt DLLs come from vcpkg. The clients end up in
`build\msvc-ninja-gui\install_cmake\bin\`:

```powershell
.\build\msvc-ninja-gui\install_cmake\bin\OMEdit.exe
```

> **Note**
> The legacy `OMShell` REPL terminal (`mosh`) needs GNU readline, which is not available for MSVC, so
> it is disabled by default here (`OM_OMSHELL_ENABLE_TERMINAL=OFF`); the `OMShell` GUI is still built.
