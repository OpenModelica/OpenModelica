/*
 * RCS: $Id$
 */
 
- OMTools is used to build OpenModelica clients OMEdit, OMShell, OMNotebook, OMPlot and OMOptim.
- Read the README.txt files of each client for more specific information about the client requirements.
 
Windows
------------------------------

  Qt 4.8.0
  ------------------------------
  - Download the Qt SDK for windows from http://qt.nokia.com/downloads.
  - Qt 4.8.0 comes with MSVC tool chain by-default. Make sure you install the MINGW tool chain also. Use the MINGW tool chain while compiling.
  - If you don't have OMDev then download it from the svn repository here https://openmodelica.ida.liu.se/svn/OpenModelica/installers/windows/OMDev.
  - Download OMDev in c:\OMDev. Set the environment variable OMDEV which points to c:\OMDev.

  Build & Run
  ------------------------------
  - Load the file OMTools.pro in Qt Creator IDE. Qt Creator is included in Qt SDK.
  - Build and run the project.

Linux
------------------------------

  Run the following commands
  ------------------------------
  - apt-get build-dep openmodelica
  - svn co https://openmodelica.org/svn/OpenModelica/trunk
  - cd trunk
  - autoconf
  - ./configure '--disable-rml-trace' 'CC=gcc-4.4' 'CXX=g++-4.4' 'CFLAGS=-O2' '--with-omniORB'
  - make -j2 qtclients

------------------------------
Adeel.
adeel.asghar@liu.se