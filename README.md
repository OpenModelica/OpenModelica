# OpenModelica [![License: OSMC-PL](https://img.shields.io/badge/license-OSMC--PL-lightgrey.svg)](OSMC-License.txt)

[OpenModelica](https://openmodelica.org) is an open-source Modelica-based modeling and simulation environment intended for industrial and academic usage.

## Dependencies (Linux/OSX) 

Many software packages are included inside the repositories.
To get everything running, you will need a few extras:

- C++11 compiler (if you want a GUI)
- autoconf, automake, libtool, gcc, g++, gfortran (pretty standard compilers)
- boost (used by omsimulator and cppruntime, configure --with-cppruntime)
- [clang](http://clang.llvm.org/), clang++ (optional, but *highly recommended*)
- [cmake](http://www.cmake.org)
- hwloc (optional; queries the number of hardware CPU cores instead of logical CPU cores)
- Java JRE (JDK is option; compiles the Java CORBA interface)
- Lapack/BLAS
- [lpsolve55](http://lpsolve.sourceforge.net)
- libhdf5 (optional part of the [MSL](https://github.com/modelica/Modelica) tables library supported by few other Modelica tools, so it does not do much)
- libexpat (it's actually included in the FMIL sources which are included... but we do not compile those and it's better to use the OS-provided dynamically linked version)
- ncurses, readline (optional, used by OMShell-terminal)
- omniORB (optional; CORBA is used by OMOptim)
- OpenSceneGraph
- Qt5 or Qt4, Webkit, QtOpenGL
- [Sundials](http://www.llnl.gov/CASC/sundials/) (optional; adds more numerical solvers to the simulation runtime)
- libcurl (libcurl4-gnutls-dev)

## Compilation

The OpenModelica Compiler is the core of the OpenModelica project, which is an open-source Modelica-based modeling and simulation environment intended for industrial and academic usage.

### Building the OpenModelica Compiler

* [Linux/OSX instructions](/OMCompiler/README.Linux.md)
* [Windows instructions](/OMCompiler/README-OMDev-MINGW.md)
* [Windows Subsystem for Linux](/OMCompiler/README-Windows-WSL.md)


## Working with the repository

OpenModelica.git is a superproject. Clone the project using one of:

```bash
# Faster pulling by using openmodelica.org read-only mirror (low latency in Europe; very important when updating all submodules)
# Replace the openmodelica.org pull URL with https://github.com/OpenModelica/OpenModelica.git if you want to pull directly from github
# The default choice is to push to your fork on github.com (SSH). Replace MY_FORK with OpenModelica to push directly to the OpenModelica repositories (if you have access)
> MY_FORK=MyGitHubUserName ; git clone https://openmodelica.org/git-readonly/OpenModelica.git --recursive && (cd OpenModelica && git remote set-url --push origin git@github.com:$MY_FORK/OpenModelica.git && git submodule foreach --recursive 'git remote set-url --push origin `git config --get remote.origin.url | sed s,^.*/,git@github.com:'$MY_FORK'/,`')
```

If you are a developer and want to update your local git repository to the latest developments or latest heads, use:

```bash
# After cloning
> cd OpenModelica
> git checkout master
> git pull
> git submodule foreach --recursive "git checkout master"
# To update; you will need to merge each submodule, but your changes will remain
> git submodule foreach --recursive "git pull"
# Running master on all submodules might lead to build errors
# so use this to make sure you force all submodules to the commits
# from the OpenModelica glue project which are properly tested
> git submodule update --force --init --recursive
```

In order to push to the repository, you will push to your own fork of OpenModelica.git, etc. You will need to create a fork of each repository that you want to push to (by clicking the Fork button in the GitHub web interface).

If you do not checkout the repositories for GUI clients (such as OMOptim.git), these directories will be ignored by autoconf and skipped during compilation.

### How to contribute to the OpenModelica Compiler

See [CONTRIBUTING.md](https://github.com/OpenModelica/OpenModelica/blob/master/CONTRIBUTING.md).

### To checkout a minimal version of OpenModelica

```bash
> git clone https://openmodelica.org/git-readonly/OpenModelica.git OpenModelica-minimal
> cd OpenModelica-minimal
> git submodule update --init --recursive libraries
```

## OpenModelica User's Guide

The [User's Guide](https://openmodelica.org/doc/OpenModelicaUsersGuide/latest/)
is automatically generated from the documentation repository.
