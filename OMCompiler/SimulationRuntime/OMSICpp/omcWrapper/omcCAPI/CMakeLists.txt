


project(${OMCCAPIName})

#name of omc c api wrapper dll


option(ENABLE_CAPI_TESTS "enable tests for c api calls" OFF)

#check if path to OpenModelica was set
if(NOT OMC_PATH)
  message(FATAL_ERROR "OpenModelica path is not set")
endif(NOT OMC_PATH)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")

#path to OpenModelica libs
if(WIN32) # Check if we are on Windows
  if(MSVC)
    set(OMC_LIB_PATH "${OMC_PATH}/lib/omc/msvc")
  else(MSVC)
    set(OMC_LIB_PATH "${OMC_PATH}/${LIB_OMC}")
    set(CMAKE_EXE_LINKER_FLAGS "-Wl,--stack,33554432")
    set(CMAKE_FIND_LIBRARY_SUFFIXES ".dll.a" ".dll" ".a")
  endif(MSVC)
elseif(UNIX)
  set(OMC_LIB_PATH "${OMC_PATH}/${LIBINSTALLEXT}/../")
else(WIN32)
  message(SEND_ERROR "You are on an unsupported platform! (Not Win32 or Unix)")
endif(WIN32)

message(STATUS "using omc paths")
message(STATUS ${OMC_PATH})
message(STATUS ${OMC_LIB_PATH})



include_directories(./include)
#search for ModelicaExtrenal C library
find_library(MODELICAEX_LIB NAMES libModelicaExternalC.a ModelicaExternalC.lib NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${OMC_LIB_PATH})
if(NOT MODELICAEX_LIB)
  message(FATAL_ERROR "Could not find ModelicaExternalC library!")
endif(NOT MODELICAEX_LIB)

#search for OpenModelica C Runtime library
find_library(OMCRUNTIME_LIB "OpenModelicaRuntimeC" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${OMC_LIB_PATH})
if(NOT OMCRUNTIME_LIB)
  message(FATAL_ERROR "Could not find OpenModelicaRuntimeC library!")
endif(NOT OMCRUNTIME_LIB)

#search for OpenModelica Compiler dll
find_library(OMC_LIB "OpenModelicaCompiler" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${OMC_LIB_PATH})
if(NOT OMC_LIB)
  message(FATAL_ERROR "Could not find OpenModelicaCompiler library!")
endif(NOT OMC_LIB)

#search for FMILib
find_library(FMI_LIB "fmilib" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${OMC_LIB_PATH})
if(NOT FMI_LIB)
  message(FATAL_ERROR "Could not find fmilib library!")
endif(NOT FMI_LIB)

find_library(OMCGC_LIB "omcgc" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${OMC_LIB_PATH})
if(NOT OMCGC_LIB)
  message(FATAL_ERROR "Could not find omcgc library!")
endif(NOT OMCGC_LIB)


#add necessary definitions
add_definitions(-DIMPORT_INTO=1)
add_definitions(-DBUILDING_OMC_DLL)



add_library(${OMCCAPIName} SHARED src/OMC.cpp)
target_link_libraries(${OMCCAPIName} ${MODELICAEX_LIB} ${OMCRUNTIME_LIB} ${OMC_LIB} ${FMI_LIB} ${OMCGC_LIB})


install(TARGETS ${OMCCAPIName} DESTINATION lib)
#INSTALL(FILES
#    include/OMC.h
#    include/OMCAPI.h
#    include/OMCFunctions.h DESTINATION include)



