cmake_minimum_required(VERSION 2.6)

# if OPENMODELICA_NEW_CMAKE_BUILD is defined (in OMCompiler/CMakeLists.txt)
# then we pick up the new cmake source.
# Otherwise we pick the old one which is needed for compilation of
# simulationruntimemsvc and is called from the Makefile.omdev.mingw files
if(OPENMODELICA_NEW_CMAKE_BUILD)
  include(cmake_3.14.cmake)
else(OPENMODELICA_NEW_CMAKE_BUILD)
  include(cmake_2.8.cmake)
endif(OPENMODELICA_NEW_CMAKE_BUILD)
