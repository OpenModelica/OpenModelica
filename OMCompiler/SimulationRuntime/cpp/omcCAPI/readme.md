Build of OMC C-API wrapper library
-----------------------------------

change to Build directory
e.g. in msys on windows
cd C:/OMCApiTest/Build

call cmake with the following arguments:
- OMC_PATH path to OpenModelica home directory
 - CMAKE_INSTALL_PREFIX installation directory for generated wrapper library

build example:
cmake -G "MSYS Makefiles" -DOMC_PATH="D:/Projekte/OMC/OpenModelica/build" -DCMAKE_INSTALL_PREFIX:String=../Binaries
make install


Interface documentation
-------------------------------------

Sources/OMC.h includes all omc api functions
see Sources/OMC.h  for documentation


Test for OMC- API  wrapper
-------------------------------------
Sources/OMCTest.cpp: Test calls api function of OMC.h
make install generates   OMCTest executable, it can be called from the build folder
./OMCExe path to OpenModelica home

