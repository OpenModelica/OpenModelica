Compilation of OMNotebook with Visual Studio (MSVC) 2008
--------------------------------------------------------
Updated by Adrian Pop [adrpo@ida.liu.se] 2008-10-02

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

Coin3D 3.0.0 and SoQt 1.4.1
 Coin3D libs+includes are needed and the sources
 need to be compiled against your Qt. SoQt provides
 bindings between Coin3D and Qt.
 http://www.coin3d.org
 http://www.coin3d.org/lib/soqt/releases/1.4.1

Open trunk.sln in Visual Studio 2008 and compile.

VARIABLES
---------
This environment variables are needed:

> OMDEV         : Should point to c:\OMDev where OMDev-mingw-msvc.zip is installed
> QNBHOME	: Should point at the folder containing the tre sub projects,
                  for example "C:\Projects\OMNotebook",
                  > used like "$(QNBHOME)\NotebookParser".
> QTHOME	: Should point at the home folder for Qt,
		  for example "C:\Qt\qt-win-opensource-src-4.4.2".
> COINDIR       : Should point at the home folder for COIN3D
                  i.e. "c:\path\to\coin3d"


Note on Linux
-------------
 If you want to compiled OMNotebook in Linux/Mac you will need to do some
 heavy editing of trunk.pro
