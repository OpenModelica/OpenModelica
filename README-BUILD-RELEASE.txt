---------------------------------------------------------------------------
         How to build the OpenModelica release on Windows using MSVC
---------------------------------------------------------------------------


             Last update 2009-11-10 Adrian Pop, adrpo@ida.liu.se

The following step-by-step guides explain how to
build the OpenModelica release .msi file on Windows
using the Microsoft Visual Studio .NET 2008

-1. Checkout the sources from Subversion:
     https://openmodelica.ida.liu.se/svn/OpenModelica/trunk -> trunk
     user: anonymous
     pass: none      <- write none here

    Checkout the VC7 directory from Subversion:
      https://openmodelica.ida.liu.se/svn/OpenModelica/installers/VC7
    into directory:
      trunk\Compiler\VC7
    IMPORTANT: VC7 HAS TO BE CHECKOUT into trunk\Compiler\VC7
               as the Visual Studio projects are based on 
               relative paths.

00. Update the version number:
    in trunk/Compiler/runtime/settings.c to "x.y.z"
    in trunk/Examples/*.onb
    in trunk/doc/*.doc + generate .pdfs

01. Please do all the steps in README-WIN32.txt
    Also you need to build the simulation runtime from c_runtime
    To do this you need to open MSYS terminal, go to trunk/c_runtime
    say: make -f Makefile.omdev.mingw

02. Additional needed files:
    - unpack trunk\Compiler\VC7\Setup\zips\mingw.tar.gz
      -> to \trunk\build\MinGW
    - take 
      https://openmodelica.ida.liu.se/svn/OpenModelica/installers/windows/VC7/Setup/zips/ModelicaLib.tar.gz
      and unpack 
      -> to \turnk\build\ModelicaLibrary
    - build trunk\OMShell then you will get a file:
      \trunk\OMShell\Release\OMShell.exe
    - build trunk\OMNotebook then you will get a file:
      trunk\OMNotebook\OMNotebookQT4\Release\OMNotebook.exe
      Also, you need to put these files in the directory:
      trunk\OMNotebook\OMNotebookQT4\Release\
      commands.xml, modelicacolors.xml, stylesheet.xml
      OMNotebookHelp.onb, pltplot.jar (from trunk/Compiler/VC7/Setup/bin/ptplot.jar)

03. Update the version into:
    - documentation
    - *.onb files
    - everywhere you might find it

04. Open the trunk/Compiler/VC7/omc/omc.snl

05. Build the project Ctrl+Shift+B

06. Open Setup, go to a file, right click on it and say->Properties Window
    Then, click on Setup and in the Properties change:
    ProductName, Title, Version to update version to x.y.z

07. Right Click in Setup choose View->"File System",
    then go to Application Folder, RightClick -> Properties Window
    change DefaultLocation to c:\OpenModelica[x.y.z]

08. Locate Uninstall.bat in the solution, edit it and replace the
    number with the latest product upgrade code.

09. Right click on Setup and say Build

10. You get a Setup.msi into trunk\Compiler\VC7\Setup\Release


That's it,
Cheers,
Adrian Pop/
