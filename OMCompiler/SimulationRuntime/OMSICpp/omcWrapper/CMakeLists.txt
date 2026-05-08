cmake_minimum_required(VERSION 3.5)

project(OMCWrapper)

set(CMAKE_VERBOSE_MAKEFILE ON)

option(USE_ZEROMQ "USE zeromq and cppzmq" ON)


#set name for omc C- api library and omc zeromq server application

set(OMCZeroMQName OMCZeroMQ)
#set include variable of omc C-api library
set(OMCCAPI_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/omcCAPI/include")

include(../CMake/CheckCXX11.cmake)

if(NOT MSVC)
  add_definitions(-DOM_HAVE_PTHREADS)
endif()

#set OpenModelica include directories
include_directories(${OMC_PATH}/include/omc/c)
include_directories(${OMC_PATH}/include/omc/)



if(MSVC)
  set(ZeroMQ_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/../../../3rdParty/libzmq/build_msvc/share/cmake/ZeroMQ")
  set(cppzmq_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../3rdParty/cppzmq/build_msvc/share/cmake/cppzmq")
else(MSVC)
  set(ZeroMQ_DIR  "${CMAKE_CURRENT_SOURCE_DIR}/../../../3rdParty/libzmq/build/share/cmake/ZeroMQ")
  set(cppzmq_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../3rdParty/cppzmq/build/share/cmake/cppzmq")
endif(MSVC)


find_package(ZeroMQ NO_DEFAULT_PATH)
find_package(cppzmq NO_DEFAULT_PATH)

#find gc library
#FIND_LIBRARY(OMCGC_LIB "gcmt-lib" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS "D:/temp/gc/Debug")
#IF(NOT OMCGC_LIB)
#  MESSAGE(FATAL_ERROR "Could not find omcgc library!")
#ENDIF(NOT OMCGC_LIB)
# MESSAGE(STATUS "omcgc library: ${OMCGC_LIB}")

#include gc library header
#include_directories ("D:\\OpenModelica\\omc\\omc_x64_cloudsim\\build\\include\\omc\\c")
message(STATUS "zeromq and cppmq found: ${ZeroMQ_FOUND}  ${cppzmq_FOUND} ")
if(ZeroMQ_FOUND AND cppzmq_FOUND)
  message(STATUS "zeromq type: ${CMAKE_BUILD_TYPE}")
  if((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))# workarround, find_package(ZeroMQ)  fails because wrong filename under windows and VS projects
    get_target_property(ZeroMQ_LIB libzmq  IMPORTED_IMPLIB_DEBUG)
    message(STATUS "Using workarround for ${ZeroMQ_LIB} " )
  else((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))
    set(ZeroMQ_LIB  ${ZeroMQ_LIBRARY})

  endif((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))

  message(STATUS "Using ZMQ library ${ZeroMQ_LIBRARY} ${ZeroMQ_LIB} " )
  message(STATUS "cppzmq version ${cppzmq_VERSION}")
  message(STATUS "Using ZMQ Header ${ZeroMQ_INCLUDE_DIR}" )
  message(STATUS "Using CPPZMQ Header ${cppzmq_INCLUDE_DIR}" )
else(ZeroMQ_FOUND AND cppzmq_FOUND)
  set(USE_ZEROMQ OFF)
  message(STATUS "zeromq was not found " )
endif(ZeroMQ_FOUND AND cppzmq_FOUND)
#link pthread
if(NOT WIN32)
  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pthread")
endif(NOT WIN32)

#omc c-api library build is only supported for mingw on Windows.
#compatible importlibrary library of the mingw dll can build
#in Visual Studio command prompt:
#dumpbin /exports libOMCDLL.dll > libOMCDLL.def
#remove all symbols except the function names
#->EXPORTS
#->fun1
#->fun2
#lib /def:libOMCDLL.def /out:libOMCDLL.lib /machine:[x86,x64]
if((NOT MSVC) AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))
  message(STATUS "build omc C- api library" )
  set(OMCCAPIName OMCDLL)
  add_subdirectory(omcCAPI)
else((NOT MSVC) AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))
  #link to the above descriped import library
  set(OMCAPI_ROOT  "${CMAKE_CURRENT_SOURCE_DIR}/../Build_CAPI/tmp/")
  message(STATUS "om c dll libary path ${OMCAPI_ROOT}" )
endif((NOT MSVC) AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))

if(USE_ZEROMQ AND COMPILER_SUPPORTS_CXX11 AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))
  message(STATUS "build omc zeromq application" )
  add_subdirectory(omcZeroMQ)
endif(USE_ZEROMQ AND COMPILER_SUPPORTS_CXX11 AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))
