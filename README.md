# OpenModelica [![License: OSMC-PL](https://img.shields.io/badge/license-OSMC--PL-lightgrey.svg)](OSMC-License.txt)

[OpenModelica](https://openmodelica.org) is an open-source Modelica-based modeling and
simulation environment intended for industrial and academic usage.

## OpenModelica User's Guide

The [User's Guide](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/) is
automatically generated from the documentation repository.

## OpenModelica environment

The [OpenModelica Compiler](OMCompiler/) is the core of the OpenModelica project.
[OMEdit](OMEdit/README.md) is the graphical user interface on top of the compiler.
[OMSimulator](OMSimulator/README.md) is a capable FMI and SSP-based Co-Simulation environment,
available as a standalone version or integrated in OMEdit.
In addition there are interactive environments
[OMNotebook](OMNotebook/README.md), [OMPlot](OMPlot/README.md) and [OMShell](OMShell/README.md)
interaction with the OMCompiler as well as various other tools:
[OMOptim](OMOptim/README.md), [OMParser](OMParser/README.md),
[OMSens_Qt](OMSens_Qt/README.md).

## Working with the repository

See [CONTRIBUTING.md](CONTRIBUTING.md#working-with-the-repository) for how to clone,
update, and clean the repository and its submodules.

TL;DR:

```bash
git clone --recurse-submodules https://github.com/OpenModelica/OpenModelica.git
```

## Build OpenModelica

* [Linux/WSL Instructions](OMCompiler/README.Linux.md)
* [Windows Instructions](OMCompiler/README.Windows.md)
* [macOS Instructions](OMCompiler/README-macOS.md)
* [CMake configuration options, tests and packaging](README.cmake.md)

We automatically generate nightly builds for
[Windows](https://openmodelica.org/download/download-windows/) and for various flavours of
[Linux](https://openmodelica.org/download/download-linux/). You can download and install
them directly if you just want to run the latest development version of OpenModelica without
the effort of compiling the sources yourself.

## How to contribute to the OpenModelica Compiler

The long-term development of OpenModelica is supported by a non-profit organization - the
[Open Source Modelica Consortium (OSMC)](https://openmodelica.org/home/consortium/).

See [CONTRIBUTING.md](CONTRIBUTING.md) on how to contribute to the development.
If you encounter any bugs, feel free to open a ticket about it.
For general questions regarding OpenModelica there is a
[discussions section](https://github.com/OpenModelica/OpenModelica/discussions) available.

## License

See [OSMC-License.txt](OSMC-License.txt).

## How to cite

See the [CITATIONS](CITATION.cff) file for information on how to cite OpenModelica in
any publications reporting work done using OpenModelica.
For a complete list of all publications related to OpenModelica see
[doc/bibliography/openmodelica.bib](./doc/bibliography/openmodelica.bib).
