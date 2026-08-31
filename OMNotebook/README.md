# OMNotebook
A Mathematica-style Notebook for OpenModelica.

## Dependencies

  - [OpenModelica Compiler](../OMCompiler)
  - [OMPlot](../OMPlot)

## Build instructions

Follow the instructions matching your OS:

  - [OMCompiler/README.Linux.md](../OMCompiler/README.Linux.md)
  - [OMCompiler/README.Windows.md](../OMCompiler/README.Windows.md)

On Windows, OMNotebook is built as part of the normal CMake `install` target (see
`OM_ENABLE_GUI_CLIENTS` in [README.cmake.md](../README.cmake.md)); no extra step is
needed. Start OMNotebook from
`/path/to/OpenModelica/build_cmake/install_cmake/bin/OMNotebook.exe`.

## Bug Reports

  - Submit bugs through the [OpenModelica GitHub issues](https://github.com/OpenModelica/OpenModelica/issues/new).
  - [Pull requests](https://github.com/OpenModelica/OpenModelica/pulls) are welcome ❤️
