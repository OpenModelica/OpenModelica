# OpenModelica CMake build instructions for MSVC

- [1. Introduction](#1-introduction)
- [2. Setup `Windows Terminal`](#2-setup-windows-terminal)
- [3. Setup `Ninja Build`](#3-setup-ninja-build)
- [4. Enable Windows Long Path Support](#4-enable-windows-long-path-support)
- [5. Setup the `vcpkg` package manager](#5-setup-the-vcpkg-package-manager)
- [6. Configure OpenModelica](#6-configure-openmodelica)
- [7. Build OpenModelica](#7-build-openmodelica)


# 1. Introduction

> **Warning**
> The OpenModelica MSVC build is highly experimental.
> If you encounter issues or have suggestions of fixes please open a new discussion or issue.

It is possible, albeit a bit complicated, to compile some of the OpenModelica tools with the **Microsoft Visual Studio Compiler** (**MSVC**).
Specifically, you can compile the OpenModelica Modelica compiler itself (`omc`) and almost all libraries needed for simulation of a Modelica model.
However, running actual simulations still needs some work.

On Windows, a package manager is necessary to get all the ubiquitous Linux libraries that we have come to depend on such as `libcurl`, `libiconv`, `gettext` and `pthreads`.
In addition, we also need to make available the bigger dependencies starting from `Lapack` all the way to `Boost`.

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
