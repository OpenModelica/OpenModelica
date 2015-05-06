# OMEdit
A Modelica connection editor for OpenModelica.

## Dependencies

- [OpenModelica](https://openmodelica.org)
- [OMPlot](../../../OMPlot)

## Build instructions

Install the dependencies.

### Unix
```bash
$ autoconf
# OPENMODELICAHOME is usually /usr, /opt, /opt/openmodelica, or /path/to/svn/OpenModelica/build
$ ./configure --prefix=/path/to/OPENMODELICAHOME
$ make
$ make install
```

### Windows MinGW
- Download the Qt SDK for windows from http://qt.nokia.com/downloads.
- Qt 4.8.0 comes with MSVC tool chain by-default. Make sure you install the MINGW tool chain also. Use the MINGW tool chain while compiling.
- If you don't have OMDev then download it from the svn repository here https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev.
- Download OMDev in c:\OMDev. Set the environment variable OMDEV which points to c:\OMDev.
- Run the Makefile.omdev.mingw via Qt Command Prompt.
```bash
$ make -f Makefile.omdev.mingw OMBUILDDIR=/path/to/OpenModelica/build
```
- Start OMEdit from /path/to/OpenModelica/build/bin/OMEdit.exe

## Bug Reports

- Submit bugs through the [OpenModelica trac](https://trac.openmodelica.org/OpenModelica/newticket).
- [Pull requests](../../pulls) are weclome.
