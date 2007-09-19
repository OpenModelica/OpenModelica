Compilation of OMNotebook with Visual Studio (MSVC)
---------------------------------------------------

The following external programs are needed:

Take OMDev from here:
http://www.ida.liu.se/~adrpo/omc/omdev/mingw/OMDev-mingw-msvc.zip
It includes msvc compiled versions of:
- ANTLR v2.7.7
- Mico 2.3.11

QT
Qt version 4 has to be installed to compile the project. Currently version 4.1,
open source is used. Version 4.1 open soure don't have any support for visual
studio, but a patch can be downloaded from sourceforge.net that allows you to
compile qt to be used together with visual studio. For more information about
this patch: http://sourceforge.net/projects/qtwin/
A guide is available at http://qtnode.net/wiki/Qt4_with_Visual_Studio



VARIABLES
---------
This environment variables are needed:

> OMDEV         : Should point to c:\OMDev where OMDev-mingw-msvc.zip is installed


> QNBHOME	: Should point at the folder containing the tre sub projects,
                  for example "C:\Projects\OMNotebook",
                  > used like "$(QNBHOME)\NotebookParser".

> QTHOME	: Should point at the home folder for Qt, 
		  for example "C:\Qt\qt-win-opensource-src-4.1.0".


MISC
----
> Probably the path to the file "omc_communicator.cc" in the OMNotebook project has
  to be change, because this path is relative also. The file is added to the project
  to avoid link error and the file is located in modelicas runtime library.


Adrian Pop [adrpo@ida.liu.se]
Updated: 2007-09-19