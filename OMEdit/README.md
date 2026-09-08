# OMEdit
A Modelica connection editor for OpenModelica.

## Dependencies

  - [OpenModelica Compiler](../OMCompiler)
  - [OMPlot](../OMPlot)
  - [OMSimulator](../../../../OMSimulator)

## Build instructions

Follow the instructions matching your OS:

  - [OMCompiler/README.Linux.md](../OMCompiler/README.Linux.md)
  - [OMCompiler/README.Windows.md](../OMCompiler/README.Windows.md)

### Compile/Debug from Qt Creator

Compile OpenModelica once with CMake using the build instructions above so all
dependencies of OMEdit are ready. Then follow these steps,

  - Open the top level `OpenModelica/CMakeLists.txt` as a project in Qt Creator.
  - Configure the project with the same compiler and CMake options you used on the
    command line. Qt Creator picks up `CMAKE_INSTALL_PREFIX` from the CMake configuration,
    so `OMEdit` ends up in the same install tree as the rest of OpenModelica.
  - Build the `install` target, or the `OMEdit` target followed by `install` if you only
    changed OMEdit sources.
  - Change the run settings to run the installed executable, e.g.
    `OpenModelica/build_cmake/install_cmake/bin/OMEdit`, so OMEdit finds `omc` and the
    shared libraries next to it.
  - Compile/debug OMEdit.

## Coding Style

  - 2 spaces not tab
  - CamelCase except that first letter should be small.
  - Member variables should start with `m` and member pointers should start with `mp`.
  - Local pointers should start with `p`.
  - Use meaningful name for variables and functions.


## Bug Reports

  - Submit bugs through the [OpenModelica GitHub issues](https://github.com/OpenModelica/OpenModelica/issues/new).
  - [Pull requests](https://github.com/OpenModelica/OpenModelica/pulls) are welcome ❤️
