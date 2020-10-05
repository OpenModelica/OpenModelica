#cmake_minimum_required(VERSION 3.0.0)



project(${OMCZeroMQName} VERSION 0.1)

set(Boost_DEBUG 1)
MESSAGE(STATUS "MINGW:")
MESSAGE(STATUS ${IS_MINGW32})
MESSAGE(STATUS ${IS_MINGW64})


IF(IS_MINGW32)
   SET(BOOST_ROOT $ENV{OMDEV}"/tools/mingw32/include")
ELSEIF(IS_MINGW64)
  SET(BOOST_ROOT $ENV{OMDEV}"/tools/mingw64/include")
ELSE()
  if(MSVC_VERSION GREATER 1800)
    MESSAGE(STATUS "USE MSVC 2015 and greater:")
    SET(Boost_COMPILER  "-vc142")
  elseif(MSVC_VERSION GREATER 1700)
    SET(BOOST_ROOT $ENV{OMDEV}"/lib/3rdParty/boost-1_59/")
  else()
     SET(BOOST_ROOT $ENV{OMDEV}"/lib/3rdParty/boost-1_55/")
  endif()
ENDIF(IS_MINGW32)
MESSAGE(STATUS "Boost root for omc - zeromq:")
MESSAGE(STATUS ${BOOST_ROOT})
FIND_PACKAGE(Boost REQUIRED COMPONENTS program_options )
IF(NOT(COMPILER_SUPPORTS_CXX11))
  FIND_PACKAGE(Threads)
  IF(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
    ADD_DEFINITIONS(-DUSE_THREAD)
    MESSAGE(STATUS "Using boost thread for omc zeromq")
  ELSE(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
    MESSAGE(STATUS "Boost thread for omc zeromq disabled")
  ENDIF(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
ELSE(NOT(COMPILER_SUPPORTS_CXX11))
 MESSAGE(STATUS "Boost thread disabled for omc zeromq because of available C++11 support")
ENDIF(NOT(COMPILER_SUPPORTS_CXX11))



MESSAGE(STATUS "using boost include for omc - zeromq:  ${Boost_INCLUDE_DIR}")
MESSAGE(STATUS "Boost Libraries for omc - zeromq:")
MESSAGE(STATUS ${Boost_LIBRARIES})
#dynamic link boost
add_definitions( -DBOOST_ALL_NO_LIB )
add_definitions( -DBOOST_ALL_DYN_LINK )
#for msvc the c-api library is not supported therfore the generated import library from the mingw dll is used
IF(MSVC)
    message (STATUS "OMC C API Root: ${OMCAPI_ROOT} " )
    SET(OMCCAPI_INLCUDE_HOME  ${OMCAPI_ROOT}/include/)
    SET(OMCCAPI_LIBRARY_RELEASE_HOME   ${OMCAPI_ROOT}/lib)
    FIND_LIBRARY(OMCCAPIName "libOMCDLL" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH
         PATHS ${OMCCAPI_LIBRARY_RELEASE_HOME} )
    message (STATUS "A ${OMCCAPIName} B" )
    IF(NOT OMCCAPIName)
        MESSAGE(FATAL_ERROR "Could not find omc c- api library ${OMCCAPI_LIBRARY_RELEASE_HOME}")
    ENDIF(OMCCAPIName)
ENDIF(MSVC)


MESSAGE(STATUS "omc c api include:")
MESSAGE(STATUS "${OMCCAPI_INLCUDE_HOME}")
MESSAGE(STATUS "omc c api library path:")
#FIND_PATH(OMCCAPI_INCLUDE_DIR OMC.h PATHS ${OMCCAPI_INLCUDE_HOME})
#IF (NOT OMCCAPI_INCLUDE_DIR)
#  MESSAGE(FATAL_ERROR "Could not find omc c- api")
#ENDIF(NOT OMCCAPI_INCLUDE_DIR)
MESSAGE(STATUS "omc c api library: ${OMCCAPIName}  includ dir: ${OMCCAPI_INCLUDE_DIR} ")



include_directories(${cppzmq_INCLUDE_DIR} ${ZeroMQ_INCLUDE_DIR}  ${OMCCAPI_INCLUDE_DIR} ${Boost_INCLUDE_DIR} include/)
ADD_EXECUTABLE(${OMCZeroMQName} src/omc.cpp src/omcZeromqTask.cpp)


#link with gc lib
#target_link_libraries(${OMCZeroMQName}   ${ZeroMQ_LIB} ${OMCCAPIName} ${Boost_LIBRARIES} ${OMCGC_LIB} )
#target_link_libraries(${OMCZeroMQName}  ${ZeroMQ_LIBRARY} ${OMCCAPIName} ${Boost_LIBRARIES}  )
target_link_libraries(${OMCZeroMQName} libzmq ${OMCCAPIName} ${Boost_LIBRARIES}  )
install(TARGETS ${OMCZeroMQName} DESTINATION bin )

