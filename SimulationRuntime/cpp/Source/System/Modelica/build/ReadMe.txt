CMake file to build Modelica System manually
Change to the build/bin director where the generated Modelica system files are located.
e.g. C:/OpenModelica/build/bin
copy the CMakefile from this folder to the bin folder
To generate the build files for the Modelica System use
cmake -G "your generator" -D   MAKE_CXX_COMPILER=g++ folder to project source dir where generate Modelica system files are located
e.g.
cmake -G "MinGW Makefiles" -D   MAKE_CXX_COMPILER=g++ C:/OpenModelica/build/bin
after that you can call 
make
e.g 
mingw32.make