Compiling OMC using OMDev package
========================================
Adrian Pop, adrpo@ida.liu.se, 2006-04-06


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
   you need on it to reflect your paths.

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

10. Available options for OMDev-MINGW-OpenModelicaBuilder
    In the Environment tab of the OMDev-MINGW-OpenModelicaBuilder
    you have several variables. 
    - OMC_BUILD_STATIC which is not present in Environment tab
      when set to "/static/" (without quotes) will compile a
      independent (static) omc.exe.

11. To run the OpenModelica testsuite you have to:
    Copy OMDev/tools/mingw to OpenModelica/build/MinGW
    To run the testsuite from Eclipse:
    - Ctrl+B and type: test
    To run the testsuite from MSYS terminal:
    - run OMDev/tools/msys/msys.bat and in the terminal you write
      >export OPENMODELICAHOME="c:\\path\\to\\your\\OpenModelica\\build"
      >cd testsuite
      testsuite> make 

For problems with OMDev package, contact:
Adrian Pop, 
adrpo@ida.liu.se
           
Last Update:2006-09-19

