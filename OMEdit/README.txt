/*
 * RCS: $Id$
 */

Windows
------------------------------

  Prerequisites
  ------------------------------
  - Compile OMC, OMPlot & qjson.

  Qt 4.8.0
  ------------------------------
  - Download the Qt SDK for windows from http://qt.nokia.com/downloads.
  - Qt 4.8.0 comes with MSVC tool chain by-default. Make sure you install the MINGW tool chain also. Use the MINGW tool chain while compiling.
  - If you don't have OMDev then download it from the svn repository here https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev.
  - Download OMDev in c:\OMDev. Set the environment variable OMDEV which points to c:\OMDev.

  Build & Run
  ------------------------------
  - Run the OMEditGUI/Makefile.omdev.mingw via Qt Command Prompt.
  - Start OMEdit from ../build/bin/OMEdit.exe.
  OR
  - Load the file OMEditGUI/OMEditGUI.pro in Qt Creator. Qt Creator is included in Qt SDK.
  - You must run the makefile once so that the parser files are generated.
  - Build the project.
  - Copy the dependent dlls from c:/OMDev/ to /location-where-OMEdit.exe-is-created. Use dependency walker (http://www.dependencywalker.com/) to find dependent dlls.
  - Run the project.
  
  Note: We recommend using the makefile. If you choose to use Qt Creator then you should take care of dependent dlls.

Linux
------------------------------

  Run the following commands
  ------------------------------
  - apt-get build-dep openmodelica
  - svn co https://openmodelica.org/svn/OpenModelica/trunk
  - cd trunk
  - autoconf
  - ./configure '--disable-rml-trace' 'CC=gcc-4.4' 'CXX=g++-4.4' 'CFLAGS=-O2' '--with-omniORB'
  - make -j2 omedit

------------------------------
Adeel.
adeel.asghar@liu.se
