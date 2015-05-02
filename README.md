# OMNotebook
A Mathematica-style Notebook for OpenModelica.

## Dependencies

- [OpenModelica](https://openmodelica.org), compiled with CORBA support
- CORBA implementation (omniORB, or possibly MICO)

## Build instructions

Install the dependencies.

```bash
$ autoconf
# OPENMODELICAHOME is usually /usr, /opt, /opt/openmodelica, or /path/to/svn/OpenModelica/build
$ ./configure --prefix=/path/to/OPENMODELICAHOME CXX=clang++
$ make
$ make install
```

## Bug Reports

- Submit bugs through the [OpenModelica trac](https://trac.openmodelica.org/OpenModelica/newticket).
- [Pull requests](../../pulls) are weclome.
