find_package(CURL REQUIRED)
find_package(Intl REQUIRED)
find_package(Iconv REQUIRED)
find_package(LAPACK REQUIRED)
# find_package(ZLIB REQUIRED) # Not needed. We use the minizip lib from 3rdParty/FMIL instead

# On Win32 we use system UUID lib which is one of the default libs that cmake adds to any target on Win32. On non Win32
# systems we need to link explicitly to uuid. However, there is no FindUUID yet. We can add one later. Instead we use
# find library for now. It should be okay for now since I am guessing uuid headers should be in the default include dirs
# anyway.
if(NOT WIN32)
  find_library(UUID_LIB NAMES uuid REQUIRED)
endif()

# ######################################################################################################################
# Library: omcruntime
add_library(omcruntime STATIC)
add_library(omc::compiler::runtime ALIAS omcruntime)

set(OMC_RUNTIIME_SOURCES
    Error_omc.cpp
    Print_omc.c
    ErrorMessage.cpp
    System_omc
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
    systemimplmisc.cpp)

target_sources(omcruntime PRIVATE ${OMC_RUNTIIME_SOURCES})
target_compile_features(omcruntime PRIVATE cxx_std_11)

target_link_libraries(omcruntime PUBLIC CURL::libcurl)
target_link_libraries(omcruntime PUBLIC ${Intl_LIBRARIES})
target_link_libraries(omcruntime PUBLIC Iconv::Iconv)
target_link_libraries(omcruntime PUBLIC ${LAPACK_LIBRARIES})
target_link_libraries(omcruntime PUBLIC OpenModelicaRuntimeC)
target_link_libraries(omcruntime PUBLIC omc::3rd::lpsolve55)
target_link_libraries(omcruntime PUBLIC omc::3rd::libzmq)
target_link_libraries(omcruntime PUBLIC omc::3rd::FMIL::minizip) # We use the minizip lib from 3rdParty/FMIL

target_include_directories(omcruntime PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(omcruntime PRIVATE ${OMCompiler_SOURCE_DIR}) # for revision.h

# uuid is one of the default libs that cmake adds to any target on Win32. On non-Win systems we look for the library and
# explicitly use it.
if(NOT WIN32)
  target_link_libraries(omcruntime PUBLIC ${UUID_LIB})
endif()

# Corba support
if(OMC_USE_CORBA)
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
endif(OMC_USE_CORBA)

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
    Dynload_omc.cpp
    FMI_omc.c
    cJSON.c)

target_sources(omcbackendruntime PRIVATE ${OMC_BACKENDRUNTIIME_SOURCES})

target_link_libraries(omcbackendruntime PUBLIC ${Intl_LIBRARIES})
target_link_libraries(omcbackendruntime PUBLIC OpenModelicaRuntimeC)
target_link_libraries(omcbackendruntime PUBLIC omc::3rd::fmilib::static)
target_link_libraries(omcbackendruntime PUBLIC omc::3rd::metis)

target_include_directories(omcbackendruntime PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(omcbackendruntime PRIVATE ${OMCompiler_SOURCE_DIR}) # for revision.h

# ######################################################################################################################
# Library: omcgraphstream
add_library(omcgraphstream STATIC)
add_library(omc::compiler::graphstream ALIAS omcgraphstream)

set(OMC_GRAPH_STREAM_SOURCES GraphStreamExt_omc.cpp)
target_sources(omcgraphstream PRIVATE ${OMC_GRAPH_STREAM_SOURCES})

target_link_libraries(omcgraphstream PUBLIC OpenModelicaRuntimeC)
target_link_libraries(omcgraphstream PUBLIC omc::3rd::netstream)
