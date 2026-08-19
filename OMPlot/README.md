# OMPlot
Plotting tool for OpenModelica-generated results files.

## Dependencies

  - [OpenModelica Compiler](../OMCompiler) (only include-files are necessary)

## Build instructions

Follow the instructions matching your OS:

  - [OMCompiler/README.Linux.md](../OMCompiler/README.Linux.md)
  - [OMCompiler/README.Windows.md](../OMCompiler/README.Windows.md)

On Windows, OMPlot is built as part of the normal CMake `install` target (see
`OM_ENABLE_GUI_CLIENTS` in [README.cmake.md](../README.cmake.md)); no extra step is
needed. Start OMPlot from `/path/to/OpenModelica/build_cmake/install_cmake/bin/OMPlot.exe`.

## Bug Reports

  - Submit bugs through the [OpenModelica GitHub issues](https://github.com/OpenModelica/OpenModelica/issues/new).
  - [Pull requests](https://github.com/OpenModelica/OpenModelica/pulls) are welcome ❤️
