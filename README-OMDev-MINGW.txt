/*
 * RCS: $Id$
 */

Compiling OMC using OMDev package
========================================
Adrian Pop, adrpo@ida.liu.se, date above.


1. Get the OMDev package from:
   http://www.ida.liu.se/~adrpo/omc/omdev/mingw
   + this package contains all prerequisites
     to compile OMC on Windows using MinGW+MSys

2. Unpack for example into:
   c:\OMDev\
   + Follow the instructions in the INSTALL file

3. You should have an OpenModelica directory you got
   from OpenModelica Subversion repository:
   svn co svn://mir20.ida.liu.se/modelica/OpenModelica/trunk/ OpenModelica

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

6. Installing Modelica Develioment Tooling (MDT) and Setting your Eclipse workspace
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

7. Setting your project.
   - File -> New -> (Modelica Project) or
     File -> New -> Project -> Modelica -> Modelica Project
   - Type the name of your OpenModelica directory installation
     For me "OpenModelica"
   - Say ok.

8. Editing the OMDev-MINGW-OpenModelicaBuilder
   - Project->Project Properties->Builders->OMDev-MINGW-OpenModelicaBuilder->Edit
   - NOTE: In tab Main you have to change the Working Directory from "OpenModelica" to
           your directory name
   - Go to Environment tab and change the name of the OMDEV variable from there
     to point to your OMDev installation:
     c/path/to/your/omdev

9. Running the OMDev-MINGW-OpenModelica builder:
   To run the OMDev-MINGW-OpenModelicaBuilder press Ctrl+B.
   Then the OMDev-MINGW-OpenModelicaBuilder will start
   and compile an OpenModelica/build/omc.exe.
   If the builder refuse to start, please check the ***NOTES*** below.

10. Available options for OMDev-MINGW-OpenModelicaBuilder
    In the Environment tab of the OMDev-MINGW-OpenModelicaBuilder
    you have several variables.
    - OMC_BUILD_STATIC which is not present in Environment tab
      when set to "/static/" (without quotes) will compile a
      independent (static) omc.exe.

11. To run the OpenModelica testsuite you have to:
    If you don't have an OpenModelicaX.Y.Z release installed
     then create a directory called OpenModelica/build/ModelicaLibrary
    in which you unpack the Modelica Standard Library you
    can take from another directory in Subversion : 
    https://openmodelica.ida.liu.se/svn/OpenModelica/installers/windows/VC7/Setup/zips/ModelicaLib.tar.gz
    To run the testsuite from Eclipse:
    - Ctrl+B and type: test
    To run the testsuite from MSYS terminal:
    - run OMDev/tools/msys/msys.bat and in the terminal you write
      >export OPENMODELICAHOME="c:\\path\\to\\your\\OpenModelica\\build"
      >export OPENMODELICALIBRARY="c:\\path\\to\\your\\OpenModelica\\build\ModelicaLibrary"
      >cd testsuite
      testsuite> make


***NOTES*** ON PROBLEMS WITH THE ECLIPSE PROJECT/OMDev BUILDER:
---------------------------------------------------------------
If something does not work in Eclipse, please check:
1. is OMDev installed into c:\OMDev?
   Be sure in C:\OMDev you have directories "tools", "bin", "include"
   and not another OMDev directory.
   Set a OMDEV variable to point to it. Right Click on
   My Computer->Properties->Advanced Tab->Environment Variables
   Add variable OMDEV and set the text to C:\OMDev
   Close and restart Eclipse to pick up the OMDEV variable.
2. rename the:
/OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder.launch-sample
to:
/OpenModelica/.externalToolBuilders/OMDev-MINGW-OpenModelicaBuilder.launch
3. right click on the OpenModelica project in Eclipse and say Refresh
4. right click on the OpenModelica project in Eclipse and say Properties
  + go to Builders and see if you have the builder :
    OMDev-MINGW-OpenModelicaBuilder available.
5. right click on the OpenModelica project and say "Rebuild"

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

Last Update:2007-03-09

