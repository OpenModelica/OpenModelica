/*
 * RCS: $Id$
 */

---------------------------------------------------------------------------
         How to build the OpenModelica release on Windows using NSIS
---------------------------------------------------------------------------


The following step-by-step guides explain how 
to build the OpenModelica setup file on Windows
using the NullSoft Scriptable Install System(NSIS)

00. Checkout the sources from Subversion:
      https://openmodelica.org/svn/OpenModelica/trunk -> trunk

    Checkout the OpenModelicaSetup directory from Subversion:
      https://openmodelica.org/svn/OpenModelica/installers/windows/OpenModelicaSetup
    into directory:
      \trunk\Compiler\OpenModelicaSetup
    IMPORTANT: OpenModelicaSetup HAS TO BE CHECKOUT into \trunk\Compiler\OpenModelicaSetup
               since the installer script uses the relative paths.
	Copy the AccessControl.dll and AccessControlW.dll to the NSIS plugins directory.

01. Update the version number:
    in trunk/Compiler/runtime/config.h to "x.y.z"
    in trunk/Examples/*.onb
    in trunk/doc/*.doc + generate .pdfs

02. If you don't have OpenModelica Development Environment setup then follow the steps in README-OMDev-MINGW.txt until step 9.
    Then make -f Makefile.omdev.mingw clean omc.
    OR
    From eclipse press Ctrl+B and type: clean omc

03. Additional needed files:
    - install python 2.7.3 and put it in your path
    - make -f Makefile.omdev.mingw install-python OR Ctrl+B and type: install-python

    - build OMClients i.e OMEdit, OMShell, OMNotebook, OMPlot, OMOptim, OMVisualize using Qt SDK.
    - make -f Makefile.omdev.mingw qtclients OR Ctrl+B and type: clean-qtclients qtclients
    - You must download and install QtSDK 4.8.0. Add Qt in your PATH.
    
    - add any new dll needed by clients into $OMDev\tools\OMTools\dll
    - if a new language file is added to OMEdit then add the corresponding qt language file into $OMDev\tools\OMTools\nls

04. Update the version into:
    - documentation
    - *.onb files
    - everywhere you might find it

05. Download and install NSIS 2.46 from http://nsis.sourceforge.net/Main_Page

06. Open the file \trunk\Compiler\OpenModelicaSetup\OpenModelciaSetup.nsi
	    Change the version number everywhere.
	    Save the changes.
	    Close the file.

07. Right click \trunk\Compiler\OpenModelicaSetup\OpenModelciaSetup.nsi and choose Compile NSIS Script.
	    A dialog will show up showing the compilation details.

08. You get a OpenModelica.exe into \trunk\Compiler\OpenModelicaSetup
      Copy it to a release folder with name:
      OpenModelica-revision-NUMBER.exe

09. Generate files in a release folder:
    See an example here:
    http://build.openmodelica.org/omc/builds/windows/nightly-builds/
    - Below, all NUMBER is the Subversion revision number 
    - OpenModelica-revision-NUMBER.exe
      + from OpenModelica.exe
    - OpenModelica-revision-NUMBER-ChangeLog.txt 
      + from Show log on subversion, until the first revision, i.e.
        in TortoiseSVN: un-check "Hide unrelated changed paths" and
        "Stop on copy/rename" and click "Show All".
    - OpenModelica-revision-NUMBER-README.txt
      + write the new important stuff here
    - OpenModelica-revision-NUMBER-testsuite-trace.txt
      + write the hudson testsuite link.
    Push the new build into:
    http://build.openmodelica.org/omc/builds/windows/nightly-builds/
    if you have the rights :) and move the old one into:
    http://build.openmodelica.org/omc/builds/windows/nightly-builds/older

10. TEST, TEST AND TEST!
    - Perfectly would be on a machine with NO VS, NO OMDEV, CLEAN WINDOWS!
    - Uninstall your current OpenModelica!
    - Delete/backup all your files from c:\OpenModelica[x.y.z]
    - Unset environment variable OMDEV (change its name to NOOMDEV)
      + this is needed to make sure no files are missing from
        C:\OpenModelica[x.y.z]\MinGW and compilation/simulation
        works fine 
    - Install the new OpenModelica
    - test OMEdit, OMShell, OMNotebook, OMPlot, OMOptim
    
11. Be extremely proud and glad, you made it! :)

12. Don't forget to re-set NOOMDEV env. var back to OMDEV :)

13. Contact us (OpenModelica@ida.liu.se) or me Adeel Asghar [adeel.asghar@liu.se] 
    with any comments, suggestions or problems regarding this document!  

Adeel Asghar.