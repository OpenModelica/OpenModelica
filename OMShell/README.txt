OMShell compilation on Linux/Unix and Windows
---------------------------------------------
Adrian Pop [adrpo@ida.liu.se] 2008-08-02


Windows
-------
The following external programs are needed:
OMDev package for Windows
 http://www.ida.liu.se/~adrpo/omc/omdev/mingw/OMDev-mingw-msvc.zip
 It includes msvc compiled versions of:
 - ANTLR v2.7.7  http://www.antlr2.org
 - Mico 2.3.13   http://www.mico.org
 On Linux you will need to compiled these for yourself.
QT 4.x
 Qt version has to be installed to compile the project.
 http://trolltech.com/downloads/opensource/appdev

Environment variables that need to be set
> OMDEV         : Should point to c:\OMDev where OMDev-mingw-msvc.zip is installed
> QNBHOME	: Should point at the folder containing the tre sub projects,
                  for example "C:\Projects\OMNotebook",
                  > used like "$(QNBHOME)\NotebookParser".
> QTHOME	: Should point at the home folder for Qt,
		  for example "C:\Qt\qt-win-opensource-src-4.4.2"

Open OMS.sln in Visual Studio 2008 and compile.


Linux
------
You will need to have mico-2.x.x compiled
- go to trunk/OMShell
- edit OMShell.pro according to your installation
  + run 'mico-config'
  + replace LIBS in OMShell.pro with the output
    you got from 'mico-config'
  + edit the INCLUDEPATH and give the mico include
    path there.
- run qmake OMShell.pro
- run make

Cheers,
Adrian/
