cmake_minimum_required(VERSION 3.5)

project(${OMCZeroMQName} VERSION 0.1)

set(Boost_DEBUG 1)
message(STATUS "MINGW: ${IS_MINGW64}")

# Check environment variables
if(WIN32)
  if(NOT DEFINED ENV{OMDEV})
    message(FATAL_ERROR "Environment variable \"OMDEV\" is not set.")
  endif()
  if(NOT DEFINED ENV{MSYSTEM_PREFIX})
    message(FATAL_ERROR "Environment variable \"MSYSTEM_PREFIX\" is not set.")
  endif()
  string(REPLACE "\\" "/" OMDEV_ESCAPED "$ENV{OMDEV}")
  string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{MSYSTEM_PREFIX}")
endif()

#Handle static vs dynamic boost linking — must be set before find_package so
#BoostConfig (1.70+) picks the matching variant. Keep this consistent with the
#BOOST_ALL_DYN_LINK / BOOST_ALL_STATIC_LINK defines added further down.
if(NOT BOOST_STATIC_LINKING)
  set(Boost_USE_STATIC_LIBS OFF)
  set(Boost_USE_STATIC_RUNTIME OFF)
else()
  set(Boost_USE_STATIC_LIBS ON)
  set(Boost_USE_STATIC_RUNTIME ON)
endif()

if(CMAKE_VERSION VERSION_LESS "3.30.0")
  FIND_PACKAGE(Boost REQUIRED COMPONENTS program_options)
else()
  FIND_PACKAGE(Boost CONFIG COMPONENTS program_options REQUIRED)
endif()

if (Boost_FOUND)
MESSAGE(STATUS "using boost include for omc - zeromq: ${Boost_INCLUDE_DIR}")
MESSAGE(STATUS "Boost Libraries for omc - zeromq: ${Boost_LIBRARIES}")
else()
MESSAGE(FATAL_ERROR "Could not found boost, Boost_LIBRARIES is empty!")
endif()

# dynamic link boost
IF(NOT BOOST_STATIC_LINKING)
add_definitions( -DBOOST_ALL_DYN_LINK )
add_definitions( -DBOOST_ALL_NO_LIB )
ELSE(NOT BOOST_STATIC_LINKING)
add_definitions( -DBOOST_ALL_STATIC_LINK -DBOOST_STATIC_LINKING )
ENDIF(NOT BOOST_STATIC_LINKING)

#for msvc the c-api library is not supported therfore the generated import library from the mingw dll is used
if(MSVC)
  message(STATUS "OMC C API Root: ${OMCAPI_ROOT} " )
  set(OMCCAPI_INLCUDE_HOME  ${OMCAPI_ROOT}/include/)
  set(OMCCAPI_LIBRARY_RELEASE_HOME ${OMCAPI_ROOT}/lib)
  find_library(OMCCAPIName "libOMCDLL" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH
       PATHS ${OMCCAPI_LIBRARY_RELEASE_HOME} )
  message(STATUS "A ${OMCCAPIName} B" )
  if(NOT OMCCAPIName)
    message(FATAL_ERROR "Could not find omc c- api library ${OMCCAPI_LIBRARY_RELEASE_HOME}")
  endif(OMCCAPIName)
endif(MSVC)


message(STATUS "omc c api include: ${OMCCAPI_INLCUDE_HOME}")
#message(STATUS "omc c api library path:")
#FIND_PATH(OMCCAPI_INCLUDE_DIR OMC.h PATHS ${OMCCAPI_INLCUDE_HOME})
#IF (NOT OMCCAPI_INCLUDE_DIR)
#  MESSAGE(FATAL_ERROR "Could not find omc c- api")
#ENDIF(NOT OMCCAPI_INCLUDE_DIR)
message(STATUS "omc c api library: ${OMCCAPIName} includ dir: ${OMCCAPI_INCLUDE_DIR} ")



include_directories(${cppzmq_INCLUDE_DIR} ${ZeroMQ_INCLUDE_DIR}  ${OMCCAPI_INCLUDE_DIR} ${Boost_INCLUDE_DIR} include/)
add_executable(${OMCZeroMQName} src/omc.cpp src/omcZeromqTask.cpp)


#link with gc lib
#target_link_libraries(${OMCZeroMQName}   ${ZeroMQ_LIB} ${OMCCAPIName} ${Boost_LIBRARIES} ${OMCGC_LIB} )
#target_link_libraries(${OMCZeroMQName}  ${ZeroMQ_LIBRARY} ${OMCCAPIName} ${Boost_LIBRARIES}  )
target_link_libraries(${OMCZeroMQName} ${Boost_LIBRARIES} libzmq ${OMCCAPIName})
install(TARGETS ${OMCZeroMQName} DESTINATION bin )
