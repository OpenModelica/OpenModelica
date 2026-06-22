find_package(CURL REQUIRED)
find_package(Intl REQUIRED)
find_package(Iconv REQUIRED)

if(OM_OMC_USE_LAPACK)
  message(STATUS "Looking for LAPACK. This can be slow sometimes. Hang tight!")
  find_package(LAPACK REQUIRED)

  # Check if our lapack version have the deprecated functions.
  set(CMAKE_REQUIRED_LIBRARIES_OLD ${CMAKE_REQUIRED_LIBRARIES})
  set(CMAKE_REQUIRED_LIBRARIES ${LAPACK_LIBRARIES})
  check_function_exists(dgeqpf_ OMC_HAVE_LAPACK_DEPRECATED)
  set(CMAKE_REQUIRED_LIBRARIES ${CMAKE_REQUIRED_LIBRARIES_OLD})
endif()

# On Win32 we use system UUID lib which is one of the default libs that cmake adds to any target on Win32. On non Win32
# systems we need to link explicitly to uuid. However, there is no FindUUID yet. We can add one later. Instead we use
# find library for now. It should be okay for now since I am guessing uuid headers should be in the default include dirs
# anyway.
if(UNIX AND NOT APPLE)
  find_library(UUID_LIB NAMES uuid REQUIRED)
endif()


# Existence checks
#################################################################################################

# Some example portability checks. Add more just like this if you need more.
# e.g this will define HAVE_TIME_H 1 if found or HAVE_TIME_H 0 otherwise
omc_check_header_exists_and_define(time.h)
# e.g this will define HAVE_CTIME_S 1 if found or HAVE_CTIME_S 0 otherwise
omc_check_function_exists_and_define(ctime_s)
omc_check_function_exists_and_define(ctime_r)



# Libraries
##################################################################################################
set(OMC_RUNTIIME_SOURCES
    Error_omc.cpp
    Dynload_omc.cpp
    Print_omc.c
    ModelInstanceReference_omc.c
    ErrorMessage.cpp
    System_omc.c
    Lapack_omc.cpp
    Settings_omc.cpp
    UnitParserExt_omc.cpp
    unitparser.cpp
    IOStreamExt_omc.cpp
    Socket_omc.c
    ZeroMQ_omc.c
    getMemorySize.c
    OMSimulator_omc.c
    is_utf8.c
    om_curl.c
    om_unzip.c
    ptolemyio_omc.cpp
    SimulationResults_omc.c
    systemimplmisc.cpp
    ffi_omc.cpp)


# ######################################################################################################################
# Library: omcruntime
add_library(omcruntime STATIC)
add_library(omc::compiler::runtime ALIAS omcruntime)

target_sources(omcruntime PRIVATE ${OMC_RUNTIIME_SOURCES})

target_link_libraries(omcruntime PUBLIC omc::config)
target_link_libraries(omcruntime PUBLIC CURL::libcurl)
target_link_libraries(omcruntime PUBLIC ${Intl_LIBRARIES})
target_link_libraries(omcruntime PUBLIC Iconv::Iconv)
target_link_libraries(omcruntime PUBLIC omc::simrt::runtime)
target_link_libraries(omcruntime PUBLIC omc::3rd::ffi)
target_link_libraries(omcruntime PUBLIC omc::3rd::libzmq)
target_link_libraries(omcruntime PUBLIC omc::3rd::simdjson)
target_link_libraries(omcruntime PUBLIC omc::3rd::zlib)

if(OM_OMC_USE_LAPACK)
  target_link_libraries(omcruntime PUBLIC ${LAPACK_LIBRARIES})
endif()

target_include_directories(omcruntime PUBLIC ${Intl_INCLUDE_DIRS})
target_include_directories(omcruntime PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# uuid is one of the default libs that cmake adds to any target on Win32. On non-Win systems we look for the library and
# explicitly use it.
if(UNIX AND NOT APPLE)
  target_link_libraries(omcruntime PUBLIC ${UUID_LIB})
endif()

# Corba support
if(OM_OMC_USE_CORBA)
  if(MINGW)
    if(DEFINED ENV{MSYSTEM_PREFIX})
      string(FIND $ENV{MSYSTEM_PREFIX} "ucrt64" IS_UCRT64)
      if(IS_UCRT64)
        message(FATAL_ERROR "No corba support on UCRT64")
      endif()
    endif()
    # setup omniORB for MinGW OMDev
    include(.cmake/omdev_omniorb_setup.cmake)
    # Include the macro for compiling corba targets.
    include(.cmake/omc_omniorb_corba_target.cmake)

    # Make a directory specifically for generated files
    set(GENERATED_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/generated)
    file(MAKE_DIRECTORY ${GENERATED_DIRECTORY})

    # add a corba target for omc_communication.idl. The outputs will be put in the generated files directory.
    omc_add_omniorb_corba_target(${OMNIIDL_EXE} ${CMAKE_CURRENT_SOURCE_DIR}/omc_communication.idl
                                 ${GENERATED_DIRECTORY})
    # Add the generated files to the sources of the library
    target_sources(omcruntime PRIVATE ${GENERATED_DIRECTORY}/omc_communication.cc omc_communication_impl.cpp
                                      Corba_omc.cpp)

    target_link_libraries(omcruntime PUBLIC omdev::omniORB::omniORB420_rt)
    target_link_libraries(omcruntime PUBLIC omdev::omniORB::omnithread40_rt)
    target_compile_definitions(omcruntime PRIVATE USE_CORBA)
    target_include_directories(omcruntime PRIVATE ${GENERATED_DIRECTORY})
  else() # Not MinGW
    message(FATAL "Corba support for non-MinGW omc builds is not yet implemented.")
  endif()
else() # No corba support requested. Use the stub file.
  target_sources(omcruntime PRIVATE corbaimpl_stub_omc.c)
endif(OM_OMC_USE_CORBA)

# Install omcruntime. It is needed by bootstrapping tests.
install(TARGETS omcruntime)



# ######################################################################################################################
# Library: omcbackendruntime
add_library(omcbackendruntime STATIC)
add_library(omc::compiler::backendruntime ALIAS omcbackendruntime)

set(OMC_BACKENDRUNTIIME_SOURCES
    HpcOmSchedulerExt_omc.cpp
    HpcOmBenchmarkExt_omc.cpp
    TaskGraphResults_omc.cpp
    ASSCEXT_omc.cpp
    BackendDAEEXT_omc.cpp
    matching.c
    matching_cheap.c
    FMI_omc.c
    cJSON.c)

target_sources(omcbackendruntime PRIVATE ${OMC_BACKENDRUNTIIME_SOURCES})

target_link_libraries(omcbackendruntime PUBLIC omc::config)
target_link_libraries(omcbackendruntime PUBLIC ${Intl_LIBRARIES})
target_link_libraries(omcbackendruntime PUBLIC omc::simrt::runtime)
target_link_libraries(omcbackendruntime PUBLIC omc::3rd::metis)
target_link_libraries(omcbackendruntime PUBLIC omc::3rd::fmilib)
target_link_libraries(omcbackendruntime PUBLIC omc::3rd::zlib)
target_link_libraries(omcbackendruntime PUBLIC omc::3rd::FMIL::expat)

target_include_directories(omcbackendruntime PUBLIC ${Intl_INCLUDE_DIRS})
target_include_directories(omcbackendruntime PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})


################################################################################
# This is a lazy approach to generating OMCompiler/omc_config.unix.h and Compiler/Util/Autoconf.mo
# Needs to be refactored quite a bit. The variable names should be updated to be more
# unique and descriptive.
# However, If I do that I need to update the .in files which means the normal compilation is
# also affected. As a result I would have to change a few things since many things depend on
# the generated output files. For now just mimic the old compilation.


# omc_config.unix.h generation lives in a standalone module so the Rust build
# can run it too (Compiler/CMakeLists.txt includes it before its early return;
# the simulation runtime needs the header but the Rust path skips this file).
# Sets the platform/compiler vars and writes omc_config.unix.h into the build
# tree; the feature vars set elsewhere in this file (above) are still in scope
# for the configure_file inside it.
include(${CMAKE_CURRENT_SOURCE_DIR}/omc_config_unix.cmake)

configure_file(${OMCompiler_SOURCE_DIR}/revision.h.in ${OMCompiler_SOURCE_DIR}/revision.h)


# Generate Autoconf.mo here since we have some of the variables already defined for omc_config.unix.h above.


check_c_compiler_flag("-Wl,-Bstatic  -Wl,-Bdynamic" BSTATIC_INT)
if(BSTATIC_INT)
  set(BSTATIC "true")
else()
  set(BSTATIC "false")
endif()

# For now assume mingw32-make is available here. It should be because it is what we use
# to compile generated simulation code on Windows when omc is issuing the compilation.
# This variable will substitute @ Autoconf.make.
# Autoconf.make inturn (at least so far) is used to issue compilation of FMU sources.
# For anything that is issued through SystemCall use this mingw32-make (instead of just 'make'
# which is the MSYS make.) since the latter is not supposed to be used on Windows shells.
# (systemCall uses 'cmd \c' to issue commands.)
if (MINGW)
  set(OMC_MAKE_EXE "mingw32-make")
else()
  if(CMAKE_HOST_SYSTEM_NAME STREQUAL "FreeBSD")
    set(OMC_MAKE_EXE "gmake")
  else()
    set(OMC_MAKE_EXE "make")
  endif()
endif()

set(OMC_CMAKE_EXE "${CMAKE_COMMAND}")

string(REPLACE ";" " " LAPACK_LIBRARIES_SPACE "${LAPACK_LIBRARIES}")

if(MINGW)
  set(CONFIG_OS "Windows_NT")
elseif(MSVC)
  set(CONFIG_OS "Windows_NT")
elseif(APPLE)
  set(CONFIG_OS "OSX")
elseif(UNIX AND NOT APPLE)
  set(CONFIG_OS ${OMC_TARGET_SYSTEM_NAME})
else()
   message(FATAL_ERROR "Unknow system for OpenModelica simulation code generation and compilation. OpenModelica does not know how to compile and simulate simulation code on this configuration.")
endif()

# RT_LDFLAGS_GENERATED_CODE* (the link flags for generated simulation/FMU code).
include(${CMAKE_CURRENT_SOURCE_DIR}/rt_ldflags_generated_code.cmake)

# Libraries linked into generated simulation code when --parmodauto is enabled (ParModelica auto + oneTBB).
# OMC_PARMODELICA_TBB_LINK_NAME is resolved to oneTBB's default library name in OMCompiler/3rdParty/CMakeLists.txt.
if(NOT OMC_PARMODELICA_TBB_LINK_NAME)
  set(OMC_PARMODELICA_TBB_LINK_NAME tbb)
endif()
set(PARMODELICAAUTO_LDFLAGS " -lParModelicaAuto -l${OMC_PARMODELICA_TBB_LINK_NAME} ")

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/../Util/Autoconf.mo.in ${CMAKE_CURRENT_SOURCE_DIR}/../Util/Autoconf.mo)
