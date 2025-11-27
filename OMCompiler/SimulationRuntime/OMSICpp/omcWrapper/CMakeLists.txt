cmake_minimum_required(VERSION 3.5)

PROJECT(OMCWrapper)

SET(CMAKE_VERBOSE_MAKEFILE ON)
#SET(CMAKE_FIND_DEBUG_MODE ON)

OPTION(USE_ZEROMQ "USE zeromq and cppzmq" ON)


#set name for omc C- api library and omc zeromq server application

SET(OMCZeroMQName OMCZeroMQ)
#set include variable of omc C-api library
SET(OMCCAPI_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/omcCAPI/include")

INCLUDE(../CMake/CheckCXX11.cmake)

if(NOT MSVC)
  add_definitions(-DOM_HAVE_PTHREADS)
endif()

#set OpenModelica include directories
INCLUDE_DIRECTORIES(${OMC_PATH}/include/omc/c)
INCLUDE_DIRECTORIES(${OMC_PATH}/include/omc/)



 IF(MSVC)
    SET(ZeroMQ_DIR  "${CMAKE_SOURCE_DIR}/../../../3rdParty/libzmq/build_msvc/share/cmake/ZeroMQ")
    SET(cppzmq_DIR "${CMAKE_SOURCE_DIR}/../../../3rdParty/cppzmq/build_msvc/share/cmake/cppzmq")
 ELSE(MSVC)
    SET(ZeroMQ_DIR  "${CMAKE_SOURCE_DIR}/../../../3rdParty/libzmq/build/share/cmake/ZeroMQ")
    SET(cppzmq_DIR "${CMAKE_SOURCE_DIR}/../../../3rdParty/cppzmq/build/share/cmake/cppzmq")
 ENDIF(MSVC)


find_package(ZeroMQ )
find_package(cppzmq )

#find gc library
#FIND_LIBRARY(OMCGC_LIB "gcmt-lib" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS "D:/temp/gc/Debug")
#IF(NOT OMCGC_LIB)
#  MESSAGE(FATAL_ERROR "Could not find omcgc library!")
#ENDIF(NOT OMCGC_LIB)
# MESSAGE(STATUS "omcgc library: ${OMCGC_LIB}")

#include gc library header
#include_directories ("D:\\OpenModelica\\omc\\omc_x64_cloudsim\\build\\include\\omc\\c")
 message (STATUS "zeromq and cppmq found: ${ZeroMQ_FOUND}  ${cppzmq_FOUND} ")
IF(ZeroMQ_FOUND AND cppzmq_FOUND)
  message (STATUS "zeromq type: ${CMAKE_BUILD_TYPE}")
    IF((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))# workarround, find_package(ZeroMQ)  fails because wrong filename under windows and VS projects
      get_target_property(ZeroMQ_LIB libzmq  IMPORTED_IMPLIB_DEBUG)
       message (STATUS "Using workarround for ${ZeroMQ_LIB} " )
    ELSE((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))
            set(ZeroMQ_LIB  ${ZeroMQ_LIBRARY})

    ENDIF((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))

    message (STATUS "Using ZMQ library ${ZeroMQ_LIBRARY} ${ZeroMQ_LIB} " )
    message(STATUS "cppzmq version ${cppzmq_VERSION}")
    message (STATUS "Using ZMQ Header ${ZeroMQ_INCLUDE_DIR}" )
    message (STATUS "Using CPPZMQ Header ${cppzmq_INCLUDE_DIR}" )
ELSE(ZeroMQ_FOUND AND cppzmq_FOUND)
    SET(USE_ZEROMQ OFF)
    message (STATUS "zeromq was not found " )
ENDIF(ZeroMQ_FOUND AND cppzmq_FOUND)
#link pthread
IF (NOT WIN32)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -pthread")
ENDIF(NOT WIN32)

#omc c-api library build is only supported for mingw on Windows.
#compatible importlibrary library of the mingw dll can build
#in Visual Studio command prompt:
#dumpbin /exports libOMCDLL.dll > libOMCDLL.def
#remove all symbols except the function names
#->EXPORTS
#->fun1
#->fun2
#lib /def:libOMCDLL.def /out:libOMCDLL.lib /machine:[x86,x64]
IF((NOT MSVC) AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))
    message (STATUS "build omc C- api library" )
    SET(OMCCAPIName OMCDLL)
    add_subdirectory(omcCAPI)
ELSE((NOT MSVC) AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))
    #link to the above descriped import library
    SET(OMCAPI_ROOT  "${CMAKE_SOURCE_DIR}/../Build_CAPI/tmp/")
    message (STATUS "om c dll libary path ${OMCAPI_ROOT}" )
ENDIF((NOT MSVC) AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))

if(USE_ZEROMQ AND COMPILER_SUPPORTS_CXX11 AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))
     message (STATUS "build omc zeromq application" )
    add_subdirectory(omcZeroMQ)
endif(USE_ZEROMQ AND COMPILER_SUPPORTS_CXX11 AND (NOT ((${CMAKE_SYSTEM_NAME} MATCHES "Darwin") )))
