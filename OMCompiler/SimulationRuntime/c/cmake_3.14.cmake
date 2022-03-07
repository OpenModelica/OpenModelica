cmake_minimum_required(VERSION 3.14)

file(GLOB OMC_SIMRT_UTIL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/util/*.c)
file(GLOB OMC_SIMRT_UTIL_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/util/*.h)

file(GLOB OMC_SIMRT_META_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/meta/*.c)
file(GLOB OMC_SIMRT_META_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/meta/*.h)

file(GLOB OMC_SIMRT_GC_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/gc/*.c)
file(GLOB OMC_SIMRT_GC_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/gc/*.h)

file(GLOB_RECURSE OMC_SIMRT_SIMULATION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/simulation/*.c
                                               ${CMAKE_CURRENT_SOURCE_DIR}/simulation/*.cpp)
file(GLOB_RECURSE OMC_SIMRT_SIMULATION_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/simulation/*.h
                                               ${CMAKE_CURRENT_SOURCE_DIR}/simulation/*.hpp)

file(GLOB OMC_SIMRT_MATH_SUPPORT_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/math-support/pivot.c)

file(GLOB OMC_SIMRT_LINEARIZATION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/linearization/linearize.cpp)
file(GLOB OMC_SIMRT_LINEARIZATION_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/linearization/linearize.h)

file(GLOB_RECURSE OMC_SIMRT_DATA_RECONCILIATION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/dataReconciliation/*.cpp)
file(GLOB_RECURSE OMC_SIMRT_DATA_RECONCILIATION_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/dataReconciliation/*.h)


file(GLOB_RECURSE OMC_SIMRT_OPTIMIZATION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/optimization/*.c)
file(GLOB_RECURSE OMC_SIMRT_OPTIMIZATION_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/optimization/*.h)


# ######################################################################################################################
# Library: OpenModelicaRuntimeC
add_library(OpenModelicaRuntimeC SHARED)
add_library(omc::simrt::runtime ALIAS OpenModelicaRuntimeC)

target_sources(OpenModelicaRuntimeC PRIVATE ${OMC_SIMRT_GC_SOURCES} ${OMC_SIMRT_UTIL_SOURCES} ${OMC_SIMRT_META_SOURCES})
target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::3rd::omcgc)

target_include_directories(OpenModelicaRuntimeC PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})


if(WIN32)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC dbghelp)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC regex)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC wsock32)
  target_link_options(OpenModelicaRuntimeC PRIVATE  -Wl,--export-all-symbols)
endif(WIN32)


install(TARGETS OpenModelicaRuntimeC)


# ######################################################################################################################
# Library: SimulationRuntimeC
add_library(SimulationRuntimeC SHARED)
add_library(omc::simrt::simruntime ALIAS SimulationRuntimeC)

target_sources(SimulationRuntimeC PRIVATE ${OMC_SIMRT_SIMULATION_SOURCES}
                                          ${OMC_SIMRT_MATH_SUPPORT_SOURCES}
                                          ${OMC_SIMRT_LINEARIZATION_SOURCES}
                                          ${OMC_SIMRT_DATA_RECONCILIATION_SOURCES})

target_link_libraries(SimulationRuntimeC PUBLIC omc::config)
target_link_libraries(SimulationRuntimeC PUBLIC omc::simrt::runtime)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::FMIL::expat)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::sundials::cvode)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::sundials::idas)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::sundials::kinsol)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::sundials::sunlinsolklu)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::sundials::sunlinsollapackdense)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::suitesparse::klu)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::suitesparse::amd)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::suitesparse::btf)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::suitesparse::colamd)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::suitesparse::umfpack)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::suitesparse::config)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::cminpack)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::cdaskr)
target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::lis)

if(WIN32)
  target_link_options(SimulationRuntimeC PRIVATE  -Wl,--export-all-symbols)
endif(WIN32)

if(WITH_IPOPT)
  target_sources(SimulationRuntimeC PRIVATE ${OMC_SIMRT_OPTIMIZATION_SOURCES})
  ## disable for now to avoid duplicate definition warnings. The define is hardcoded in
  ## omc_config.h. Until we remove that this just results in warnings.
  # target_compile_definitions(SimulationRuntimeC PRIVATE -DWITH_IPOPT)
  target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::ipopt)
endif()

# Fix me. Make an interface (header only library) out of 3rdParty/dgesv
target_include_directories(SimulationRuntimeC PRIVATE ${OMCompiler_SOURCE_DIR}/3rdParty/dgesv/include/)

# target_link_options(SimulationRuntimeC PRIVATE  -Wl,--no-undefined)

install(TARGETS SimulationRuntimeC)


# ######################################################################################################################
# include the configuration for (source code) FMI runtime and generate RuntimeSources.mo
# This is separated into another file just for clarity. Once it is cleaned up and organized
# it can be brought back here.
include(cmake/source_code_fmu_config.cmake)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo.cmake ${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo)



# ######################################################################################################################
## Install the header files. This installs the whole directory structure of c/ folder
## which means all headers will be installed keeping the directory structure intact.
## It might install some unneeded headers but it suffices for now.
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        TYPE INCLUDE
        FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.c.inc"
        # To skip the build dir created by the normal Makefiles build system.
        PATTERN "build" EXCLUDE
        # This is skipped by the makefiles and instead some header files from SimulationRuntime/fmi
        # are instead added to c/fmi folders. Until we fix those we keep this for now :(
        PATTERN "fmi" EXCLUDE
)

