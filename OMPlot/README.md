# OMPlot
Plotting tool for OpenModelica-generated results files.

## Dependencies

  - [OpenModelica Compiler](../OMCompiler) (only include-files are necessary)

## Build instructions

Follow the instructions matching your OS:

  - [OMCompiler/README.Linux.md](../OMCompiler/README.Linux.md)
  - [OMCompiler/README.Windows.md](../OMCompiler/README.Windows.md)

### Windows MSYS Makefiles

If you used MSYS Makefiles to compile OpenModelica you need one additional step:

Start a MSYS terminal `$OMDEV_MSYS\ucrt64.exe` and run:

```bash
$ cd /path/to/OpenModelica
make -f Makefile.omdev.mingw omplot -j<Nr. of cores>
```
Start OMPlot from `/path/to/OpenModelica/build/bin/OMPlot.exe`

## Bug Reports

  - Submit bugs through the [OpenModelica GitHub issues](https://github.com/OpenModelica/OpenModelica/issues/new).
  - [Pull requests](https://github.com/OpenModelica/OpenModelica/pulls) are welcome ❤️
