cpp code generation for OMC cpp Solver interface


When you use the cpp code generator for the first time you have to build all libraries, please see the build mechanism section
below

Folder structure:

In the folder of the omc trunk you can find the folder SimulationRuntim/cpp with the subfolders 
Sources: this includes the generated cpp code for the modelica model,solvers, simulation runtime, etc
Build: folder for  out-of-source build


configuration of solver and simulation
you can copy to the Binaries/config folder the settings GlobalSettings.xml and your selected solver settings 
from the source/solver/yoursolver/interfaces and source/settingsfactory/interfaces folder and modify it. 
Othterwise the settings files are copied to the config folder with the default settings.
	  
Build mechanism

Please delete all binaries files in the Binaries folder before you compile all libraries, to avoid linker errors 

To  build the cpp solver interface  you need cmake (http://www.cmake.org/) you can download it for your operation system 
from here: http://www.cmake.org/cmake/resources/software.html 

Cpp Simulation runtime installation:
In the file trunk/SimulationRuntime/cpp/Source/CMakeLists.txt at the beginning the used 3rdPary libraries are configured.
For Windows Boost, Lapack and Blas are from the OMDEV folder used else the installed versions are used. 
The cpp solver interface uses the additional boost.extension header files which are not
yet part of the official boost release. If you are not using the boost libraries from OMDEV you can download the boost.extension library
from boost svn: https://svn.boost.org/trac/boost/browser/sandbox/libs/extension or download it from the boost extension web site and copy the header 
files to you boost header files folder.

To generate the build files for out-of-source build call cmake from the build folder: trunk/SimulationRuntime/cpp/build :
cmake -G "your generator" -D  CMAKE_INSTALL_PREFIX:PATH="Insall directory" MAKE_CXX_COMPILER=g++ folder to project source dir

e.g for MinGW and Windwos (you need the mingw/bin dir in you path environment variable)
cmake -G "MinGW Makefiles" -D  CMAKE_INSTALL_PREFIX:PATH="C:/OpenModelica/build" MAKE_CXX_COMPILER=g++ C:/OpenModelica/SimulationRuntime/cpp/Source
after that you can call
make install
e.g. 
mingw32-make install
This copies all shared libs and needed header files to build the Modelica System to installation directory




In the Binaries folder is after the build the Simulation.exe







