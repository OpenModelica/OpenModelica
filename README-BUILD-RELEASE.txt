---------------------------------------------------------------------------
         How to build the OpenModelica release on Windows using MSVC
---------------------------------------------------------------------------

           
             Last update 2006-10-07 Adrian Pop, adrpo@ida.liu.se

The following step-by-step guides explain how to 
build the OpenModelica release .msi file on Windows 
using the Microsoft Visual Studio .NET 2003

0. Update the version number:
   in trunk/Compiler/runtime/settings.c to "x.y.z"
   in trunk/Examples/*.onb
   in trunk/doc/*.doc + generate .pdfs

1. Please do all the steps in README-WIN32.txt
   Also you need to build the simulation runtime from c_runtime
   To do this you need to open MSYS terminal, go to trunk/c_runtime
   say: make -f Makefile.omdev.mingw 

2. Create a drive called M: 
   subst m: c:\OpenModelicaRelease
   [to delete the drive use subst m: /d]

3. Within drive M: copy:
   - unpacked trunk\Compiler\VC7\Setup\zips\mingw.tar.gz       
     -> to M:\MinGW
   - unpacked trunk\Compiler\VC7\Setup\zips\ModelicaLib.tar.gz 
     -> to M:\ModelicaLibrary
   - copy C:\bin\cygwin\home\adrpo\dev\OpenModelica\OMNotebook\DrModelica 
     -> to M:\DrModelica
   - build trunk\OMShell then put all the files below:
     OMShell.exe, mico2311.dll, msvcp71.dll, msvcr71.dll, QtCore4.dll, QtGui4.dll
     into:
     M:\OMShell\release\       
   - build trunk\OMNotebook then put all the files below:
     OMNotebook.exe, mico2311.dll, msvcp71.dll, msvcr71.dll, QtCore4.dll, QtGui4.dll
     QtNetwork4.dll, QtXml4.dll, commands.xml, modelicacolors.xml, stylesheet.xml
     OMNotebookHelp.onb, pltplot.jar (from trunk/Compiler/VC7/Setup/bin/ptplot.jar) 
     into:
     M:\OMNotebook\release\

4. Open the trunk/Compiler/VC7/omc/omc.snl

5. Build the project Ctrl+Shit+B

6. Open Setup, go to a file, right click on it and say->Properties Window
   Then, click on Setup and in the Properties change:
   ProductName, Title, Version to update version to x.y.z

7. Right Click in Setup choose View->"File System", 
   then go to Application Folder, RightClick -> Properties Window
   change DefaultLocation to c:\OpenModelica[x.y.z]
 
8. Right click on Setup and say Build

9. You get a Setup.msi into trunk\Compiler\VC7\Setup\Release

That's it,
Cheers,
Adrian Pop/