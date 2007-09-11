---------------------------------------------------------------------------
         How to build the OpenModelica release on Windows using MSVC
---------------------------------------------------------------------------

           
             Last update 2007-09-07 Adrian Pop, adrpo@ida.liu.se

The following step-by-step guides explain how to 
build the OpenModelica release .msi file on Windows 
using the Microsoft Visual Studio .NET 2003

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
    - unpack trunk\Compiler\VC7\Setup\zips\ModelicaLib.tar.gz 
      -> to \turnk\build\ModelicaLibrary
    - build trunk\OMShell then you will get a file:
      \trunk\OMShell\Release\OMShell.exe       
    - build trunk\OMNotebook then you will get a file:
      trunk\OMNotebook\OMNotebookQT4\Release\OMNotebook.exe
      Also, you need to put these files in the directory:
      trunk\OMNotebook\OMNotebookQT4\Release\  
      QtCore4.dll, QtGui4.dll, QtNetwork4.dll, QtXml4.dll, commands.xml, modelicacolors.xml, stylesheet.xml
      OMNotebookHelp.onb, pltplot.jar (from trunk/Compiler/VC7/Setup/bin/ptplot.jar) 
      
03. Update the version into:
    - documentation
    - *.onb files
    - everywhere you might find it 

04. Open the trunk/Compiler/VC7/omc/omc.snl

05. Build the project Ctrl+Shit+B

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

11. For Windows Vista release you have to edit the Setup.msi with Orca.exe: 
    http://msdn2.microsoft.com/en-us/library/Aa370557.aspx
    http://download.microsoft.com/download/platformsdk/sdk/update/win98mexp/en-us/3790.0/msisdk-common.3.0.cab
    Go to CustomAction Table and change the action type from 1042 to 3090. 
    This elevates the privileges for the custom action and allows it to run.

That's it,
Cheers,
Adrian Pop/