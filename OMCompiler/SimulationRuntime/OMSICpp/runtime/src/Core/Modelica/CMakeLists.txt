cmake_minimum_required(VERSION 3.5...4.3)

project(${ModelicaName})

# this library is only for the precompiled header
add_library(${ModelicaName} STATIC Modelica.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ModelicaName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")

endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${ModelicaName} ${Boost_LIBRARIES})

if(MSVC)
  set(LINKER_LIB_PREFIX "")
else(MSVC)
  set(LINKER_LIB_PREFIX "-l")
endif(MSVC)

if(${CMAKE_SYSTEM_NAME} MATCHES "Linux")
  include(CheckTypeSize)
  check_type_size("void*" SIZEOF_VOID_P BUILTIN_TYPES_ONLY)
  set(LINUX_LIB_DL "-ldl")
  set(FPIC "-fPIC")
  if(${SIZEOF_VOID_P} MATCHES 8)
    set(FMI_ARCH_DIR "linux64")
  else(${SIZEOF_VOID_P} MATCHES 8)
    set(FMI_ARCH_DIR "linux32")
  endif(${SIZEOF_VOID_P} MATCHES 8)
endif(${CMAKE_SYSTEM_NAME} MATCHES "Linux")

if(${CMAKE_SYSTEM_NAME} MATCHES "Windows")
  set(LINUX_LIB_DL "")
  set(FMI_ARCH_DIR "win32")
endif(${CMAKE_SYSTEM_NAME} MATCHES "Windows")

set(BOOST_INCLUDE ${Boost_INCLUDE_DIRS})

get_target_property(TARGET_TYPE ${ModelicaName} TYPE)
if(TARGET_TYPE STREQUAL "STATIC_LIBRARY")
  set(MODELICA_SYSTEM_LIB_EXT ${CMAKE_STATIC_LIBRARY_SUFFIX})
elseif(TARGET_TYPE STREQUAL "SHARED_LIBRARY")
  set(MODELICA_SYSTEM_LIB_EXT ${CMAKE_SHARED_LIBRARY_SUFFIX})
endif()

#Fix to enable debugging for gcc
#Problem: The ModelicaConfig.inc file contains something like "optimized;<lib>;debug;<lib>" if the debug or relwithdebinfo -flag is set. The gcc is not able to handle this after the linker-flag (-L).
#Quick Fix: Pick the debug libraries out of the list if the debug or relwithdebinfo -flag is set.
#Maybe someone with more cmake-experience can write a better solution for the issue.
#mwalther

string(TOUPPER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE)

function(prepareBoostVar targetVar releaseVar debugVar)
  if(CMAKE_BUILD_TYPE MATCHES "RELEASE")
    set(targetVar_ ${releaseVar})
  else()
    set(targetVar_ ${debugVar})
  endif(CMAKE_BUILD_TYPE MATCHES "RELEASE")
  get_filename_component(${targetVar_} "${${targetVar_}}" NAME_WE)
  string(REGEX REPLACE "^lib" "" "${targetVar_}" "${${targetVar_}}")
  set(${targetVar} ${${targetVar_}} PARENT_SCOPE)
endfunction()

prepareBoostVar(Boost_FILESYSTEM_LIBRARY Boost_FILESYSTEM_LIBRARY_RELEASE Boost_FILESYSTEM_LIBRARY_DEBUG)
prepareBoostVar(Boost_SERIALIZATION_LIBRARY Boost_SERIALIZATION_LIBRARY_RELEASE Boost_SERIALIZATION_LIBRARY_DEBUG)
prepareBoostVar(Boost_THREAD_LIBRARY Boost_THREAD_LIBRARY_RELEASE Boost_THREAD_LIBRARY_DEBUG)
prepareBoostVar(Boost_PROGRAM_OPTIONS_LIBRARY Boost_PROGRAM_OPTIONS_LIBRARY_RELEASE Boost_PROGRAM_OPTIONS_LIBRARY_DEBUG)
prepareBoostVar(Boost_LOG_LIBRARY Boost_LOG_LIBRARY_RELEASE Boost_LOG_LIBRARY_DEBUG)

if(CMAKE_BUILD_TYPE)
  set(Boost_LIBRARIES_NEW "")
  set(SKIP_ENTRY OFF)
  if((CMAKE_BUILD_TYPE MATCHES "DEBUG") OR (CMAKE_BUILD_TYPE MATCHES "RELWITHDEBINFO"))
    foreach(f ${Boost_LIBRARIES})
      if(NOT SKIP_ENTRY)
        if(${f} MATCHES "optimized")
          set(SKIP_ENTRY ON)
        elseif(${f} MATCHES "debug")

        else(${f} MATCHES "optimized")
          list(APPEND Boost_LIBRARIES_NEW ${f})
        endif(${f} MATCHES "optimized")
      else(NOT SKIP_ENTRY)
        if(${f} MATCHES "debug")
          set(SKIP_ENTRY OFF)
        endif(${f} MATCHES "debug")
      endif(NOT SKIP_ENTRY)
    endforeach(f ${Boost_LIBRARIES})
  else()
    foreach(f ${Boost_LIBRARIES})
      if(NOT SKIP_ENTRY)
        if(${f} MATCHES "debug")
          set(SKIP_ENTRY ON)
        elseif(${f} MATCHES "optimized")

        else(${f} MATCHES "debug")
          list(APPEND Boost_LIBRARIES_NEW ${f})
        endif(${f} MATCHES "debug")
      else(NOT SKIP_ENTRY)
        if(${f} MATCHES "optimized")
          set(SKIP_ENTRY OFF)
        endif(${f} MATCHES "optimized")
      endif(NOT SKIP_ENTRY)
    endforeach(f ${Boost_LIBRARIES})
  endif()
  set(Boost_LIBRARIES_ ${Boost_LIBRARIES_NEW})
endif(CMAKE_BUILD_TYPE)

if(WIN32)
  # Check environment variables
  if(NOT DEFINED ENV{MSYSTEM_PREFIX})
    message(FATAL_ERROR "Environment variable \"MSYSTEM_PREFIX\" is not set.")
  endif()
  string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{MSYSTEM_PREFIX}")

  if(MSVC)
    set(Boost_LIBS_ "$(OMHOME)/bin/msvc")
  else(MSVC)
    set(Boost_LIBS_ "$(OMHOME)/bin")
  endif(MSVC)

  if(MSVC)
    set(Boost_INCLUDE_ "$(OMHOME)/include/omc/omsicpp/3rdParty/boost/msvc/")
  else(MSVC)
    set(Boost_INCLUDE_ "$(MSYSTEM_PREFIX_ESCAPED)/include/")
  endif(MSVC)

  set(SUNDIALS_LIBS_ "$(OMHOME)/bin")
  set(SUNDIALS_INCLUDE_DIR_ "$(OMHOME)/include/omc/omsicpp/sundials")
  set(LAPACK_LIBS_ "$(OMHOME)/bin")
else(WIN32)
  if("${Boost_LIBRARY_DIRS}" STREQUAL "")
    set(Boost_LIBS_ ".")
  else()
    set(Boost_LIBS_ ${Boost_Library_folder})
  endif()
  if("${Boost_INCLUDE_DIR}" STREQUAL "" OR
     "${Boost_INCLUDE_DIR}" STREQUAL "/usr/include")
    # standard /usr/include collides with cross compilation
    set(Boost_INCLUDE_ ".")
  else()
    set(Boost_INCLUDE_ ${Boost_INCLUDE_DIR})
  endif()
  if("${SUNDIALS_LIBS}" STREQUAL "")
    set(SUNDIALS_LIBS_ ".")
  else()
    set(SUNDIALS_LIBS_ ${SUNDIALS_LIBS})
  endif()
  if("${SUNDIALS_INCLUDE_DIR}" STREQUAL "" OR
     "${SUNDIALS_INCLUDE_DIR}" STREQUAL "/usr/include")
    # standard /usr/include collides with cross compilation
    set(SUNDIALS_INCLUDE_DIR_ ".")
  else()
    set(SUNDIALS_INCLUDE_DIR_ ${SUNDIALS_INCLUDE_DIR})
  endif()
  if("${LAPACK_LIBS}" STREQUAL "")
    set(LAPACK_LIBS_ ".")
  else()
    set(LAPACK_LIBS_ ${LAPACK_LIBS})
  endif()
endif(WIN32)

set(UMFPACK_LIBS_ "${SUITESPARSE_UMFPACK_LIBS}")

if("${TBB_INCLUDE_DIR}" STREQUAL "")
  set(TBB_INCLUDE_DIR_ ".")
else()
  set(TBB_INCLUDE_DIR_ ${TBB_INCLUDE_DIR})
endif()

if("${PUGIXML_INCLUDE_DIR}" STREQUAL "")
  set(PUGIXML_INCLUDE_DIR_ ".")
else()
  set(PUGIXML_INCLUDE_DIR_ ${PUGIXML_INCLUDE_DIR})
endif()

if("${SUITESPARSE_UMFPACK_INCLUDE_DIR_OMC}" STREQUAL "")
  set(UMFPACK_INCLUDE_ ".")
else()
  set(UMFPACK_INCLUDE_ "${SUITESPARSE_UMFPACK_INCLUDE_DIR_OMC}")
endif()

set(Boost_LIBRARIES_NEW)
foreach(lib ${Boost_LIBRARIES_})
  # Convert "Boost:SomeCrazyLib" to "-lboost_SomeCrazyLib" for ModelicaConfig_gcc.inc
  if(${CMAKE_VERSION} VERSION_GREATER "3.16.0") # support newer cmake >= 3.16
    get_target_property(libNew "${lib}" LOCATION)
    if("${libNew}" STREQUAL "libNew-NOTFOUND") # could not find it
      set(libNew ${lib})
    endif("${libNew}" STREQUAL "libNew-NOTFOUND")
    get_filename_component(libNew "${libNew}" NAME_WE)
  else(${CMAKE_VERSION} VERSION_GREATER "3.16.0") # support older cmake <= 3.16
    get_filename_component(libNew "${lib}" NAME_WE)
  endif(${CMAKE_VERSION} VERSION_GREATER "3.16.0")
  string(REGEX REPLACE "^lib" "" libNew ${libNew})
  set(Boost_LIBRARIES_NEW "${Boost_LIBRARIES_NEW} ${LINKER_LIB_PREFIX}${libNew}")
endforeach()
set(Boost_LIBRARIES_ ${Boost_LIBRARIES_NEW})

set(SUNDIALS_LIBARIES_ "")
if(TARGET omc::3rd::sundials::cvode)
  # Integrated CMake build: SUNDIALS_LIBRARIES contains CMake targets, not paths.
  # Derive the linker flags directly from the known static library names.
  set(SUNDIALS_LIBRARIES_
    " ${LINKER_LIB_PREFIX}sundials_nvecserial_static"
    " ${LINKER_LIB_PREFIX}sundials_cvode_static"
    " ${LINKER_LIB_PREFIX}sundials_cvodes_static"
    " ${LINKER_LIB_PREFIX}sundials_idas_static"
    " ${LINKER_LIB_PREFIX}sundials_kinsol_static")
  string(REPLACE ";" "" SUNDIALS_LIBRARIES_ "${SUNDIALS_LIBRARIES_}")
else()
  foreach(lib ${SUNDIALS_LIBRARIES})
    get_filename_component(libNew "${lib}" NAME_WE)
    string(REGEX REPLACE "^lib" "" libNew ${libNew})
    set(SUNDIALS_LIBRARIES_ "${SUNDIALS_LIBRARIES_} ${LINKER_LIB_PREFIX}${libNew}")
  endforeach(lib ${SUNDIALS_LIBRARIES})
endif()

set(LAPACK_LIBRARIES_ "")
foreach(lib ${LAPACK_LIBRARIES})
  get_filename_component(libNew "${lib}" NAME_WE)
  string(REGEX REPLACE "^lib" "" libNew ${libNew})
  set(LAPACK_LIBRARIES_ "${LAPACK_LIBRARIES_} ${LINKER_LIB_PREFIX}${libNew}")
endforeach(lib ${LAPACK_LIBRARIES})

set(INTEL_TBB_LIBS "")
foreach(lib ${TBB_LIBRARIES})
  get_filename_component(libNew "${lib}" NAME_WE)
  string(REGEX REPLACE "^lib" "" libNew ${libNew})
  set(INTEL_TBB_LIBS "${INTEL_TBB_LIBS} ${LINKER_LIB_PREFIX}${libNew}")
endforeach(lib ${TBB_LIBRARIES})

set(UMFPACK_LIBS "")
foreach(lib ${SUITESPARSE_UMFPACK_LIBRARIES_OMC})
  get_filename_component(libNew "${lib}" NAME_WE)
  string(REGEX REPLACE "^lib" "" libNew ${libNew})
  set(UMFPACK_LIBRARIES_ "${UMFPACK_LIBRARIES_} ${LINKER_LIB_PREFIX}${libNew}")
endforeach(lib ${SUITESPARSE_UMFPACK_LIBRARIES_OMC})
#end Fix

message(STATUS " ")
message(STATUS "Values for *.inc files:")
message(STATUS "--BOOST_LIBS = ${Boost_LIBS_} " - " ${Boost_Library_folder}")
message(STATUS "--BOOST_INCLUDE = ${Boost_INCLUDE_}")
message(STATUS "--BOOST_LIBRARIES = ${Boost_LIBRARIES_} ${CPPTHREADS_LIBRARY_}")
message(STATUS "--SUNDIALS_LIBS = ${SUNDIALS_LIBS_}")
message(STATUS "--SUNDIALS_INCLUDE = ${SUNDIALS_INCLUDE_DIR_}")
message(STATUS "--SUNDIALS_LIBRARIES = ${SUNDIALS_LIBRARIES_}")
message(STATUS "--LAPACK_LIBS = ${LAPACK_LIBS_}")
message(STATUS "--LAPACK_LIBRARIES = ${LAPACK_LIBRARIES_}")
message(STATUS "--UMFPACK_LIBS = ${SUITESPARSE_UMFPACK_LIBS}")
message(STATUS "--UMFPACK_INCLUDE = ${UMFPACK_INCLUDE_}")
message(STATUS "--UMFPACK_LIBRARIES = ${UMFPACK_LIBRARIES_}")
message(STATUS "--CPPTHREADS_LIBRARY = ${CPPTHREADS_LIBRARY} ${CPPTHREADS_LIBRARY_FLAG}")
message(STATUS " ")

if(BUILD_SHARED_LIBS)
  create_precompiled_header(${ModelicaName} runtime/include/Core/Modelica.h)
endif(BUILD_SHARED_LIBS)

if(MSVC)
  if(BUILD_SHARED_LIBS)
    message(STATUS "MSVC config file generated in ${PROJECT_BINARY_DIR}/ModelicaConfig_msvc.inc")
    message(STATUS  ${SYSTEM_CFLAGS} )
    get_target_property(libModelica ${ModelicaName} LOCATION)
    get_filename_component(libModelicaName ${libModelica} NAME)
    set(PCH_LIB ${libModelicaName})
    configure_file (
    "ModelicaConfig_msvc.inc.in"
    "${PROJECT_BINARY_DIR}/ModelicaConfig_msvc.inc"
    )
    install (FILES
            ${PROJECT_BINARY_DIR}/ModelicaConfig_msvc.inc
            DESTINATION include/omc/omsicpp)

    configure_file (
    "ModelicaLibraryConfig_msvc.inc.in"
    "${PROJECT_BINARY_DIR}/ModelicaLibraryConfig_msvc.inc"
    )
    install (FILES
            ${PROJECT_BINARY_DIR}/ModelicaLibraryConfig_msvc.inc
            DESTINATION include/omc/omsicpp)
  endif(BUILD_SHARED_LIBS)
endif(MSVC)

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel" OR "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")
  configure_file (
    "ModelicaConfig_gcc.inc.in"
    "${PROJECT_BINARY_DIR}/ModelicaConfig_gcc.inc")
  install (FILES
      ${PROJECT_BINARY_DIR}/ModelicaConfig_gcc.inc
      DESTINATION include/omc/omsicpp)

  configure_file (
  "ModelicaLibraryConfig_gcc.inc.in"
  "${PROJECT_BINARY_DIR}/ModelicaLibraryConfig_gcc.inc"
  )
  install (FILES
        ${PROJECT_BINARY_DIR}/ModelicaLibraryConfig_gcc.inc
        DESTINATION include/omc/omsicpp)
else()
endif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Intel" OR "${CMAKE_CXX_COMPILER_ID}" MATCHES "Clang")

install(TARGETS ${ModelicaName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/Modelica.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/ModelicaDefine.h
  DESTINATION include/omc/omsicpp/Core)
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/Policies/TextfileWriter.h
  DESTINATION include/omc/omsicpp/Core/DataExchange/Policies)
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/Policies/MatfileWriter.h
  DESTINATION include/omc/omsicpp/Core/DataExchange/Policies)
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Core/DataExchange/Policies/BufferReaderWriter.h
  DESTINATION include/omc/omsicpp/Core/DataExchange/Policies)
