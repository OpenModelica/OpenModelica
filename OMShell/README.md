# OMShell

## Dependencies

- [OpenModelica](https://openmodelica.org)

## Build instructions

Install the dependencies.

### Unix
```bash
$ autoconf
# OPENMODELICAHOME is usually /usr, /opt, /opt/openmodelica, or /path/to/OpenModelica/build
$ ./configure --prefix=/path/to/OPENMODELICAHOME CXX=clang++
$ make
$ make install
```

### Windows MinGW
- If you don't have OMDev then download it from the svn repository [here](https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev).
- Follow the instructions in [INSTALL.txt](https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev/INSTALL.txt).
- Open msys terminal. Either `$OMDEV/tools/msys/mingw32_shell.bat` OR `$OMDEV/tools/msys/mingw64_shell.bat`.
```bash
$ cd /path/to/OpenModelica
$ make -f Makefile.omdev.mingw omshell
```
- Start OMShell from `/path/to/OpenModelica/build/bin/OMShell.exe`

## Bug Reports

- Submit bugs through the [OpenModelica trac](https://trac.openmodelica.org/OpenModelica/newticket).
- [Pull requests](../../../pulls) are welcome.
