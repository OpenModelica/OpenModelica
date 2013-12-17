/*
 * RCS: $Id$
 */

Windows
------------------------------

  Prerequisites
  ------------------------------
  - Compile OMPlot.

  Qt 4.8.0
  ------------------------------
  - Download the Qt SDK for windows from http://qt.nokia.com/downloads.
  - Qt 4.8.0 comes with MSVC tool chain by-default. Make sure you install the MINGW tool chain also. Use the MINGW tool chain while compiling.
  - If you don't have OMDev then download it from the svn repository here https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev.
  - Download OMDev in c:\OMDev. Set the environment variable OMDEV which points to c:\OMDev.

  Build & Run
  ------------------------------
  - Run the OMEditGUI/Makefile.omdev.mingw via Qt Command Prompt.
  OR
  - Load the file OMEditGUI/OMEditGUI.pro in Qt Creator IDE. Qt Creator is included in Qt SDK.
  - Build and run the project.
  - Copy omniORB416_rt.dll, omniORB416_rtd.dll, omnithread34_rt.dll and omnithread34_rtd.dll from c:/OMDev/lib/omniORB-4.1.6-mingw/bin/x86_win32 to /location-where-OMEdit.exe-is-created.
  - Copy qwt.dll and qwtd.dll from c:/OMDev/lib/qwt-6.1.0-mingw/lib to /location-where-OMEdit.exe-is-created.

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
