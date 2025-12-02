# OpenModelica CMake build instructions for MSVC

- [OpenModelica CMake build instructions for MSVC](#openmodelica-cmake-build-instructions-for-msvc)
- [1. Introduction](#1-introduction)
- [2. Setup `Windows Terminal`](#2-setup-windows-terminal)
- [3. Setup `Ninja Build`](#3-setup-ninja-build)
- [4. Setup the `vcpkg` package manager.](#4-setup-the-vcpkg-package-manager)
- [5. Configure OpenModelica](#5-configure-openmodelica)
- [6. Build OpenModelica](#6-build-openmodelica)


# 1. Introduction

> **Warning**
> The OpenModelica MSVC build is highly experimental. If you encounter issues or have suggestions of fixes please open a new discussion or issue.

It is possible, albeit a bit complicated, to compile some of the OpenModelica tools with the `Microsoft Visual Studio Compiler (MSVC)`. Specifically, you can compile the OpenModelcia Modelica compiler itself (`omc`) and almost all libraries needed for simulation of a
Modelica model. However, running actual simulations still needs some work.

Unfortunately, it is not possbile to compile `OMEdit`, `OMNotebook` and `OMShell` yet because of missing `QtWebkit` support.

On Windows, a package manager is necessary to get all the ubiquitous Linux libraries that we have come to depend on such as `libcurl`, `libiconv`, `gettext` and `pthreads`. In addition, we also need to make available the bigger dependencies starting from `Lapack` all the way to `Boost`, `Qt`, `OpenGl`, and `OpenSceneGraph`.

These instructions are intended to be used with:
- The `Windows Terminal` terminal.
- The `Ninja Build` build tool.
- The Microsoft `vcpkg` package manager.

You can probably follow this instructions without using the first two tools above if you know what you are doing. However, forgoing `vcpkg` is not possbile without a lot of extra work. It is recommended to use this tools at least as an initial step since those tools are where these instrcutions are tested on.

# 2. Setup `Windows Terminal`

If you do not have it already, **it is highly recommended to install and use** [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=sv-se&gl=se) from the Microsoft Store. You can also install it [manually](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=sv-se&gl=se) if you prefer. This terminal is much superior and configurable than the default Windows CMD terminal. It will also detect and setup sheels like Developer PowerShell and CMD for Visual Studio automatically which should make things easier going forward.

# 3. Setup `Ninja Build`

These instruction are also for the [Ninja](https://ninja-build.org/) build tool. Ninja is chosen because it is portable accross Windows, Linux and macOS. It is also straightforward to perform parallelized builds with `Ninja` (in fact it is the default behavior). In addition, it is the closest tool to GNU Make compared to MSBuild or NMake, which should make it easier to follow for those coming from the `Linux`, `macOS`, and the `GNU Make` ecosystems. That said, you can use your preferred generator and adjust the CMake commands in this document accordingly.

Recent Visual Studio versions should come with `Ninja` by default in the `C++ CMake tools for Windows` installation component. You can check the existence of Ninja on your system by launching a Developer PowerShell for Visual Studio and running the command

> **Note**
> If you have installed the Windows Terminal app  (see [1. Windows Terminal](#1-setup-Windows-Terminal`)), then the Developer PowerShell For Visual Studio will available in the consols list and you can just open it from there and proceed.

```powershell
Get-Command ninja.exe
```

> **Warning**
> If you want to use a normal PowerShell or CMD terminal, make sure you make the Visual Studio tools available as they might not be available by default. Refer to the Microsoft [documentation](https://learn.microsoft.com/en-us/cpp/build/building-on-the-command-line?view=msvc-170) for more info.


If you do not have Ninja available, you can just download the binary from [Ninja Github Repository](https://github.com/ninja-build/ninja/releases) and put it in the `CMake\bin\` directory (e.g., `C:\Program Files\CMake\bin`) to make sure it available wherever CMake is available.


# 4. Setup the `vcpkg` package manager.

The next thing to do is to clone the vcpkg repo at the root of OpenModelica. This will be setup as a local package manager which will install packages only for the current project leaving the rest of your system completely unaffected (except for some temporary files and cache in your TEMP folders). **It will install all packages under the CMake build directory** that you specify.

```sh
cd OpenModelica
git clone https://github.com/microsoft/vcpkg.git
```

Next we need to create a file named `vcpkg.json` in the OpenModleica directory with the following contents

```json
{
  "name": "openmodelica",
  "version-string": "1.22.0",
  "homepage": "https://openmodelica.org/",
  "description": "an open-source Modelica-based modeling and simulation environment intended for industrial and academic usage.",
  "dependencies": [
    "curl",
    "libiconv",
    "gettext",
    "lapack",
    "pthread",
    "expat",
    "dirent",
    "boost-program-options",
    "boost-filesystem",
    "boost-ublas",
    "boost-lambda",
    "boost-asio",
    "boost-circular-buffer",
    "boost-graph",
    "boost-chrono"
  ]
}
```

This file tells vcpkg which packages to install in [manifest mode](https://vcpkg.readthedocs.io/en/latest/users/manifests/). Think of a `package.json` file for node.js.

> **Note**
> This file might eventually be part of the OpenModelica repository. However, for the time being, it is better to create it locally until the whole configuration and build is tested well and has stabelized.

# 5. Configure OpenModelica

Configuring OpenModelica for MSVC with vcpkg and Ninja is almost identical to configuring for other OSs and compilers. The only thing we have to do is tell CMake that our packages are provided by the vcpkg package manager instead of being installed system wide, i.e., the packages we install using vcpkg are actually **installed within the CMake build folder we have specified**. We can tell OpenModelica's CMake configuration to use vcpkg by setting the variable `OM_WITH_VCPKG=ON` on the configuration command line.

We are now ready to configure OpenModelica for Visual Studio. Open a `Developer PowerShell For Visual Studio` terminal and configure OpenModelica:

```powershell
cd OpenModelica
cmake -S . -B build_msvc_ninja -Wno-dev -DOM_WITH_VCPKG=ON -DOM_USE_CCACHE=OFF -DOM_ENABLE_GUI_CLIENTS=OFF -DOM_OMC_ENABLE_FORTRAN=OFF -DOM_OMC_ENABLE_OPTIMIZATION=OFF -DOM_OMC_ENABLE_MOO=OFF -G "Ninja"
```

We have
  - Enabled OpenModelica `vcpkg` usage with `OM_WITH_VCPKG=ON`
  - Disabled `ccache` usage since we have not installed it and its functionality with MSVC is subpar anyway.
  - Disabled all the GUI clinets since `QtWebkit` is not available for Windows through vcpkg.
  - Disabled `Fortran` support since we do not have a Fortran compiler.
  - Disabled `IpOpt` since it requires Fortran support.

This should configure OpenModelica and generate the build directory `OpenModelica/build_msvc_ninja`.


# 6. Build OpenModelica
If the configuration finished successfully, proccede to building OpenModleica

```powershell
cd OpenModelica
cmake --build build_msvc_ninja --target install
```

The first build of the project will take a considerable amount of time due to the following:

- `vcpkg` will 'boostrap' itself. Basically it just builds itself from source (It is not clear what the boostrapping part is here but in the end you will get the vcpkg executable). It might download a prebuilt binary for your system (if available) to save time and resources.
- `vcpkg` will download the sources, build, and locally install all the packages listed in the `vcpkg.json` file. It might download prebuilt binaries for your system (if available) to save time and resources. This can take several minutes so monitor the progress.
- once the packages are built and installed, CMake will start building the project.

> **Note**
> Subsequent builds should be faster compared to the first one since `vcpkg` will do nothing unless the `vcpkg.json` file is modified, i.e., a package is added or removed.

If the build process completed successfully, CMake will install the project into `OpenModelica/build_msvc_ninja/install_cmake/` directory.

Check if omc is installed and working

```powershell
.\install_cmake\bin\omc.exe --help
```

If this prints the omc help strings, omc is compiled properly and can be used to generate model code. Actually compiling the generated model code and simulating models still needs some fixes.


