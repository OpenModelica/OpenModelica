# OMEdit
A Modelica connection editor for OpenModelica.

## Dependencies

- [OpenModelica](https://openmodelica.org)
- [OMPlot](../OMPlot)
- [OMSimulator](../../../../OMSimulator)

## Build instructions

Install the dependencies.

### Unix
```bash
$ autoconf
# OPENMODELICAHOME is usually /usr, /opt, /opt/openmodelica, or /path/to/OpenModelica/build
$ ./configure --prefix=/path/to/OPENMODELICAHOME
$ make
$ make install
```

### Windows MinGW
- If you don't have OMDev then download it from the svn repository [here](https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev).
- Follow the instructions in [INSTALL.txt](https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev/INSTALL.txt).
- Open msys terminal. Either `$OMDEV/tools/msys/mingw32_shell.bat` OR `$OMDEV/tools/msys/mingw64_shell.bat`.
```bash
$ cd /path/to/OpenModelica
$ make -f Makefile.omdev.mingw omedit
```
- Start OMEdit from `/path/to/OpenModelica/build/bin/OMEdit.exe`

## Coding Style

- 2 spaces not tab
- CamelCase except that first letter should be small.
- Member variables should start with `m` and member pointers should start with `mp`.
- Local pointers should start with `p`.
- Use meaningful name for variables and functions.


## Bug Reports

- Submit bugs through the [OpenModelica trac](https://trac.openmodelica.org/OpenModelica/newticket).
- [Pull requests](../../../pulls) are welcome.
