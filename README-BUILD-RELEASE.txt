/* 
 * RCS: $Id$ 
 */

---------------------------------------------------------------------------
         How to build the OpenModelica release on Windows using MSVC
---------------------------------------------------------------------------


             Previous update: 2010-04-27 Adrian Pop, Adrian.Pop@liu.se 
             Last update:     2012-02-10 Adrian Pop, Adrian.Pop@liu.se

BIG WARNING:
 THIS DOCUMENT IS OBSOLETE!
 We have discontinued the Visual Studio .NET 2010 build since some years now!
 You could still try to build it, but don't expect any help :)

The following step-by-step guides explain how to
build the OpenModelica release .msi file on Windows
using the Microsoft Visual Studio .NET 2010

BIG NOTE WARNING!
 - DO NOT ADD MinGW and omclibrary to the Setup project ever again
   as it takes *FOREVER* to delete them from it. Instead save the project
   before adding them as the last step before building, add them then
   build the .msi, then replace Setup.vdproj with the copy you made!
 - This is done to keep Setup.vdproj small and sort of like template
   (See also Step 11).
 - Visual Studio Setup projects are crap! 
   The more files you add the slower they move!
   Also, the biggest issue is that you can add directories by drag-and-drop
   from Windows Explorer BUT YOU CANNOT DELETE THEM ANYMORE! You will have 
   to delete each file in each directory added until you can delete the 
   directories! 

00. Checkout the sources from Subversion:
     https://openmodelica.org/svn/OpenModelica/trunk -> trunk

    Checkout the VC7 directory from Subversion:
      https://openmodelica.org/svn/OpenModelica/installers/windows/VC7
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
    
    Note that changes in the way we handle OPENMODELICALIBRARY
    and what changes happened to the trunk\libraries since
    last change in Setup.vdproj have to be taken into account.
    Currently libraries in trunk\libraries are copied to 
    \trunk\build\lib\omlibrary.  
    
04. Additional needed files:
    - take qtlibs from:
      https://www.ida.liu.se/~adrpo/omc/omdev/qtlibs/
      unpack it, point it by environment variable QTHOME
    - svn checkout https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev
      -> to \trunk\build\MinGW
      Clean up (to be easy to add MinGW to the Setup.vdproj, otherwise it takes forever!):
       REMOVE all .svn directories from it! Search .svn, select all .svn directories, Delete!
       REMOVE MinGW\lib\mlton
       REMOVE MinGW\share\doc\mlton
       ZIP    MinGW\doc\*.* to MinGW\doc\doc.zip and delete them
       ZIP    MinGW\info\*.* to MinGW\info\info.zip and delete them
       ZIP    MinGW\man\*.* to MinGW\man\man.zip and delete them
      Note that this step will have to be repeated starting from svn checkout 
      again if anything has changed in svn MinGW directory since last build. 
      
    - add files *.xml (commands.xml, modelicacolors.xml, stylesheet.xml) in the directory:
      trunk\OMNotebook\OMNotebookQT4\
      to \trunk\build\share\omnotebook and \trunk\build\share\omshell 
    - add file OMNotebookHelp.onb in the directory:
      trunk\OMNotebook\OMNotebookQT4\
      to \trunk\build\share\omnotebook
    - add pltplot.jar (from trunk/Compiler/VC7/Setup/bin/ptplot.jar)
      to \trunk\build\bin
    - build OMShell, OMNotebook, OMPlot, OMOptim, OMPlotWindow using Qt SDK
      into $OMDev\tools\OMTools\bin
    - update $OMDev\tools\OMTools\qtdlls with the newest from Qt SDK!

05. Update the version into:
    - documentation
    - *.onb files
    - everywhere you might find it

06. Open the trunk/Compiler/VC7/omc/omc.snl

07. DO NOT build the omc project!
    Select all files in the Setup project and in the property window change 
    Vital to false to prevent re-installation if any of the files are replaced! 

08. Open Setup, go to a file, right click on it and say->Properties Window
    Then, click on Setup and in the Properties change:
    ProductName, Title, Version to update version to x.y.z

09. Right Click in Setup choose View->"File System",
    then go to Application Folder, RightClick -> Properties Window
    change DefaultLocation to c:\OpenModelica[x.y.z]

10. Locate Uninstall.bat in the solution, edit it and replace the
    number with the latest product upgrade code.

11. Save Setup.vdproj, Exit Visual Studio, make a copy of Setup.vdproj
    Note: We DO NOT SAVE THE Setup.vdproj AFTER WE ADDED
          trunk\build\MinGW and trunk\build\omc\omlibrary
          to it as it takes FOREVER to delete them from
          the FileSystemView!! 
    Open Visual Studio and do these steps: 
    - add trunk\build\MinGW to the FileSystemView
      in the Visual Studio project here: \MinGW
    - add trunk\build\lib\omlibrary to the FileSystemView
      in the Visual Studio project here: lib\omlibrary
    - select all files in the Setup project in the Solution explorer
      and change in the property window Vital to false!
    - SAVE All  
    - right click on Setup project and say Build
    - fix any errors that might appear!
    - REPLACE Setup.vdproj with the
      copy you made at the start of Step 11
      so that it doesn't include MinGW and omclibrary!

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
    - test OMShell, OMNotebook, OMEdit, OMPlot*, OMOptim
    
15. Be extremely proud and glad, you made it! :)

16. Don't forget to re-set NOOMDEV env. var back to OMDEV :)

17. Contact us (OpenModelica@ida.liu.se) or me Adrian Pop [Adrian.Pop@liu.se] 
    with any comments, suggestions or problems regarding this document!  

That's it,
Cheers,
Adrian Pop/
