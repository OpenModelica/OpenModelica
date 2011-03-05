---------------------------------------------------------------------------
         How to build the OpenModelica release on Windows using MSVC
---------------------------------------------------------------------------


             Previous update: 2010-04-27 Adrian Pop, Adrian.Pop@liu.se 
             Last update:     2011-03-05 Adrian Pop, Adrian.Ppo@liu.se

The following step-by-step guides explain how to
build the OpenModelica release .msi file on Windows
using the Microsoft Visual Studio .NET 2010

00. Checkout the sources from Subversion:
     https://openmodelica.org/svn/OpenModelica/trunk -> trunk
     user: anonymous
     pass: none      <- write none here

    Checkout the VC7 directory from Subversion:
      https://openmodelica.org/svn/OpenModelica/installers/VC7
    into directory:
      trunk\Compiler\VC7
    IMPORTANT: VC7 HAS TO BE CHECKOUT into trunk\Compiler\VC7
               as the Visual Studio projects are based on 
               relative paths.

01. Update the version number:
    in trunk/Compiler/runtime/settings.c to "x.y.z"
    in trunk/Examples/*.onb
    in trunk/doc/*.doc + generate .pdfs

02. Please do all the steps in README-OMDev-MINGW.txt
    use: make clean testlog
    zip trunk\testsuite directory into trunk\testsuite.zip!

03. ADD ALL NEW FILES TO THE SETUP PROJECT WHERE THEY BELONG, 
    i.e. new files from trunk\build\include\omc
    into the File System Setup from the project in the
    Application Folder\include\omc\. Same of lib or any
    other files you might need for the build. All new
    libraries that are used for linking add them to
    Application Folder\lib\omc\.
    See in Subversion which files were added since the
    last modification of Setup.vdproj
    
04. Additional needed files:
    - take qtlibs from:
      https://www.ida.liu.se/~adrpo/omc/omdev/qtlibs/
      unpack it, point it by environment variable QTHOME
    - unpack trunk\Compiler\VC7\Setup\zips\mingw-3.4.5.tar.gz
      -> to \trunk\build\MinGW
    - take 
      copy trunk\libraries\msl*
      -> to \trunk\build\
    - build trunk\OMShell then you will get a file:
      \trunk\OMShell\Release\OMShell.exe
    - build trunk\OMNotebook then you will get a file:
      trunk\OMNotebook\OMNotebookQT4\Release\OMNotebook.exe
      Also, you need to put these files in the directory:
      trunk\OMNotebook\OMNotebookQT4\Release\
      commands.xml, modelicacolors.xml, stylesheet.xml
      OMNotebookHelp.onb, pltplot.jar (from trunk/Compiler/VC7/Setup/bin/ptplot.jar)

05. Update the version into:
    - documentation
    - *.onb files
    - everywhere you might find it

06. Open the trunk/Compiler/VC7/omc/omc.snl

07. DO NOT build the omc project!

08. Open Setup, go to a file, right click on it and say->Properties Window
    Then, click on Setup and in the Properties change:
    ProductName, Title, Version to update version to x.y.z

09. Right Click in Setup choose View->"File System",
    then go to Application Folder, RightClick -> Properties Window
    change DefaultLocation to c:\OpenModelica[x.y.z]

10. Locate Uninstall.bat in the solution, edit it and replace the
    number with the latest product upgrade code.

11. Right click on Setup project and say Build
    Fix any errors that might appear!

12. You get a Setup.msi into trunk\Compiler\VC7\Setup\Release
    Copy it to a release folder with name:
    OpenModelica-revision-NUMBER.msi

13. Generate files in a release folder:
    See an example here:
    http://build.openmodelica.org/omc/builds/windows/nightly-builds/
    - Below, all NUMBER is the Subversion revision number 
    - OpenModelica-revision-NUMBER.msi 
      + from Setup.msi
    - OpenModelica-revision-NUMBER-ChangeLog.txt 
      + from Show log on subversion, until the first revision, i.e.
        in TortoiseSVN: un-check "Hide unrelated changed paths" and
        "Stop on copy/rename" and click "Show All".
    - OpenModelica-revision-NUMBER-README.txt
      + write the new important stuff here
    - OpenModelica-revision-NUMBER-testsuite-trace.txt.txt
      + from trunk\testsuite\testsuite-trace.txt
    Push the new build into:
    http://build.openmodelica.org/omc/builds/windows/nightly-builds/
    if you have the rights :) and move the old one into:
    http://build.openmodelica.org/omc/builds/windows/nightly-builds/older

14. TEST, TEST AND TEST!
    - Perfectly would be on a machine with NO VS, NO OMDEV, CLEAN WINDOWS!
    - Uninstall your current OpenModelica!
    - Delete/backup all your files from c:\OpenModelica[x.y.z]
    - Unset environment variable OMDEV (change its name to NOOMDEV)
      + this is needed to make sure no files are missing from
        C:\OpenModelica[x.y.z]\MinGW and compilation/simulation
        works fine
    - Install the new OpenModelica
    - test OMShell, OMNotebook, OMEdit, OMPlot*
    
15. Be extremely proud and glad, you made it! :)

16. Contact us (OpenModelica@ida.liu.se) or me Adrian Pop [Adrian.Pop@liu.se] 
    with any comments, suggestions or problems regarding this document!  

That's it,
Cheers,
Adrian Pop/
