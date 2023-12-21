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
    ffi_omc.c)


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

target_include_directories(omcbackendruntime PUBLIC ${Intl_INCLUDE_DIRS})
target_include_directories(omcbackendruntime PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})


################################################################################
# This is a lazy approach to generating OMCompiler/omc_config.unix.h and Compiler/Util/Autoconf.mo
# Needs to be refactored quite a bit. The variable names should be updated to be more
# unique and descriptive.
# However, If I do that I need to update the .in files which means the normal compilation is
# also affected. As a result I would have to change a few things since many things depend on
# the generated output files. For now just mimic the old compilation.


set(SHREXT ${CMAKE_SHARED_LIBRARY_SUFFIX})
string(TOLOWER ${CMAKE_SYSTEM_NAME} OMC_TARGET_SYSTEM_NAME)
omc_add_to_report(OMC_TARGET_SYSTEM_NAME)
set(OPENMODELICA_SPEC_PLATFORM ${CMAKE_SYSTEM_PROCESSOR}-${OMC_TARGET_SYSTEM_NAME})

if(${CMAKE_SIZEOF_VOID_P} EQUAL 8)
  set(OMC_TARGET_ARCH_IS_64 "true")
  set(MODELICA_SPEC_PLATFORM "${OMC_TARGET_SYSTEM_NAME}64")
else()
  set(OMC_TARGET_ARCH_IS_64 "false")
  set(MODELICA_SPEC_PLATFORM "${OMC_TARGET_SYSTEM_NAME}32")
endif()

set(host_short ${CMAKE_LIBRARY_ARCHITECTURE})

set(RUNTIMECC ${CMAKE_C_COMPILER})
set(CC ${CMAKE_C_COMPILER})
set(CXX ${CMAKE_CXX_COMPILER})

find_package(OpenMP)
if(OpenMP_FOUND)
  set(OMPCFLAGS "-fopenmp")
endif()

if(LAPACK_FOUND)
  set(HAVE_LAPACK "#define HAVE_LAPACK")
  if(OMC_HAVE_LAPACK_DEPRECATED)
    set(HAVE_LAPACK_DEPRECATED "#define HAVE_LAPACK_DEPRECATED")
  endif()
endif()


if(OpenMP_FOUND)
  set(CONFIG_WITH_OPENMP 1)
else()
  set(CONFIG_WITH_OPENMP 0)
endif()

set(OMC_HAVE_IPOPT "/* OMC_HAVE_IPOPT Not needed for CMake build. Availability and use of ipopt is handled by the CMakefiles.*/")

set(WITH_SUITESPARSE "#define WITH_SUITESPARSE")
set(WITH_HWLOC 0)
set(WITH_UUID "#define WITH_LIBUUID 1")


set(USE_GRAPH 0)

set(RUNTIMECFLAGS "-fPIC -DOM_HAVE_PTHREADS")

configure_file(${OMCompiler_SOURCE_DIR}/revision.h.in ${OMCompiler_SOURCE_DIR}/revision.h)
configure_file(${OMCompiler_SOURCE_DIR}/omc_config.unix.h.in ${OMCompiler_SOURCE_DIR}/omc_config.unix.h)


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
  set(OMC_MAKE_EXE "make")
endif()

set(OMC_CMAKE_EXE "${CMAKE_COMMAND}")

string(REPLACE ";" " " LAPACK_LIBRARIES_SPACE "${LAPACK_LIBRARIES}")

if(MINGW)
  set(CONFIG_OS "Windows_NT")

  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -lopenblas -lm -lpthread ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic -lopenblas -lm -lpthread -lgfortran -lstdc++ ")

elseif(MSVC)
  set(CONFIG_OS "Windows_NT")

  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lopenblas -lm -lpthread -lgfortran -lstdc++ ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -lopenblas -lm -lpthread ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic -lopenblas -lm -lpthread -lgfortran -lstdc++ ")

elseif(APPLE)
  set(CONFIG_OS "OSX")

  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -llapack -lblas -lm")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-lSimulationRuntimeFMI -llapack -lblas -lm")

elseif(UNIX AND NOT APPLE)
  set(CONFIG_OS ${OMC_TARGET_SYSTEM_NAME})

  set(RT_LDFLAGS_GENERATED_CODE " -lOpenModelicaRuntimeC -lomcgc -llapack -lblas -lm -lpthread -rdynamic")
  set(RT_LDFLAGS_GENERATED_CODE_SIM " -lSimulationRuntimeC -lOpenModelicaRuntimeC -lomcgc -lzlib -llapack -lblas -lm -ldl -lpthread -lgfortran -lstdc++ -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU " -llapack -lblas -lm -lpthread -rdynamic ")
  set(RT_LDFLAGS_GENERATED_CODE_SOURCE_FMU_STATIC "-Wl,-Bstatic -lSimulationRuntimeFMI -Wl,-Bdynamic -llapack -lblas -lm -ldl -lpthread -lgfortran -lstdc++ -rdynamic ")

else()
   message(FATAL_ERROR "Unknow system for OpenModelica simulation code generation and compilation. OpenModelica does not know how to compile and simulate simulation code on this configuration.")
endif()

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/../Util/Autoconf.mo.in ${CMAKE_CURRENT_SOURCE_DIR}/../Util/Autoconf.mo)
