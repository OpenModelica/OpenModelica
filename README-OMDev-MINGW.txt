/*
 * RCS: $Id$
 */

Compiling OMC using OMDev package
========================================
Adrian Pop, Adrian.Pop@liu.se, date above.


1. Checkout the OMDev package from Subversion:
   https://openmodelica.org/svn/OpenModelicaExternal/trunk/tools/windows/OMDev
   + this package contains all prerequisites to compile OMC on Windows using MinGW+MSys
   + NOTE THAT YOU MUST UPDATE THIS PACKAGE IF YOU CANNOT COMPILE OpenModelica any longer!

2. Make sure you place the OMDev package into:
   c:\OMDev\
   + Follow the instructions in the INSTALL file

3. You should have an OpenModelica directory you got
   from OpenModelica Subversion repository:
   svn co https://www.openmodelica.org/svn/OpenModelica/trunk/ OpenModelica
   user: anonymous
   pass: none    <-- write "none" here   

4. inside the OpenModelica directory you will find a .project-sample file
   which you should rename to OpenModelica/.project and do whatever modifications
   you need on it to reflect your paths. Windows doesn't let you create files
   that start with dot (.) so you do like this:
   Copy your .project-sample to .project again from DOS:
   Start->Run->cmd.exe
   $ cd \path\to\OpenModelica
   $ ren ".project-sample" ".project" 

5. rename the file the OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder.launch-sample
   to OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder.launch and do whatever
   modifications are needed on it to reflect your paths.

6. Installing Modelica Development Tooling (MDT) and setting your Eclipse workspace
   Start Eclipse and follow instructions from:
   http://www.ida.liu.se/~pelab/modelica/OpenModelica/MDT/
   to install MDT. Eclipse will restart at the end.
   Start Eclipse, change workspace to your installation:
   - note here that your workspace must point one directory
     up the OpenModelica svn directory (for me named OpenModelica)
     Example: if you downloaded OpenModelica in a directory like this:
     c:\some_paths\dev\OpenModelica then your workspace must point to:
     c:\some_patsh\dev\
   - The Eclipse restarts

7. To compile the OpenModelica clients (OMNotebook, OMShell, OMEdit,...) you need to install qt from:
   - http://download.qt-project.org/archive/qt/4.8/4.8.0/qt-win-opensource-4.8.0-mingw.exe
   - Ignore error message (say ok) of the missing MiniGW installation (it's already included in OMDev)

8. Setting your project.
   - File -> New -> (Modelica Project) or
     File -> New -> Project -> Modelica -> Modelica Project
   - Type the name of your OpenModelica directory installation
     For me "OpenModelica"
   - Say Finish.

9. Editing the OMDev-MINGW-OpenModelicaBuilder
   - Project->Project Properties->Builders->OMDev-MINGW-OpenModelicaBuilder->Edit
   - NOTE: In tab Main you have to change the Working Directory from "OpenModelica" to
           your directory name
   - Go to Environment tab and change the name of the OMDEV variable from there
     to point to your OMDev installation:
     /c/path/to/your/omdev (/c/OMDev)
   - To compile qtclints you need to edit (add, not replace) in the same tab
     the eclipse PATH variable with your qt path. (e.g. "c:/qt/4.8.0/bin/;")

10. Running the OMDev-MINGW-OpenModelica builder:
    To run the OMDev-MINGW-OpenModelicaBuilder press Ctrl+B or right-click project and say rebuild.
    Then the OMDev-MINGW-OpenModelicaBuilder will start
    and compile an OpenModelica/build/omc.exe.
    If the builder refuse to start, please check the ***NOTES*** below.

11. Available options for OMDev-MINGW-OpenModelicaBuilder
    In the Environment tab of the OMDev-MINGW-OpenModelicaBuilder
    you have several variables.
    - OMC_BUILD_STATIC which is not present in Environment tab
      when set to "/static/" (without quotes) will compile a
      independent (static) omc.exe.
    - to build omc for a release you need to make it static.

12. To install the Modelica Standard Library into the build directory:
    - Ctrl+B and type: omlibrary

13. To build the OpenModelica clients:
    - Ctrl+B and type: qtclients
      Compiles OMNotebook, OMShell, OMEdit, OMPlot, OMVisualize, OMOptim
      Copies the binaries in trunk\build\bin and libraries in trunk\build\lib

14. To run the OpenModelica testsuite:
    - Ctrl+B and type: testlog
      Will get you a trunk\testsuite\testsuite-trace.txt
    To run the testsuite from MSYS terminal:
    - run OMDev/tools/msys/msys.bat and in the terminal you write
      >export OPENMODELICAHOME="c:\\path\\to\\your\\OpenModelica\\build"
      # If you use a different path than OPENMODELICAHOME/lib/omlibrary/...
      >export OPENMODELICALIBRARY="c:\\path\\to\\your\\OpenModelica\\build\\lib\\omlibrary"
      >cd testsuite
      testsuite> make
      
15. To install the OpenModelica Python Interface:
    - Ctrl+B and type: install-python
      Generates the python stub files.
      Copies the OMPython files in trunk\build\share\omc\scripts\PythonInterface


***NOTES*** ON PROBLEMS WITH THE ECLIPSE PROJECT/OMDev BUILDER:
---------------------------------------------------------------
If something does not work in Eclipse, please check:
1. is the Modelica perspective chosen in eclipse?
   Set it up in the right top corner.
2. is OMDev installed into c:\OMDev?
   Be sure in C:\OMDev you have directories "tools", "bin", "include"
   and not another OMDev directory.
   Set a OMDEV variable to point to it. Right Click on
   My Computer->Properties->Advanced Tab->Environment Variables
   Add variable OMDEV and set the text to C:\OMDev
   Close and restart Eclipse to pick up the OMDEV variable.
3. rename the:
/OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder.launch-sample
to:
/OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder.launch
4. right click on the OpenModelica project in Eclipse and say Refresh
5. right click on the OpenModelica project in Eclipse and say Properties
  + go to Builders and see if you have the builder :
    OMDev-MINGW-OpenModelicaBuilder available.
6. right click on the OpenModelica project and say "Rebuild"

If these do not work, look into your OpenModelica/.project
to see if you have any reference to: OMDev-MINGW-OpenModelicaBuilder
there. If you don't, then:
- close Eclipse
- copy your .project-sample to .project again from DOS:
  Start->Run->cmd
  $ cd \path\to\OpenModelica
  $ ren ".project-sample" ".project"
- open Eclipse and do step 3-5 above.


For problems with OMDev package, contact:
Adrian Pop,
adrpo@ida.liu.se

Last Update:     2013-12-17
Previous Update: 2011-03-05