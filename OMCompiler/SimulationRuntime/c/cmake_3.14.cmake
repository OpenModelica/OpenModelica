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

file(GLOB OMC_SIMRT_FMI_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/fmi/*.c)
file(GLOB OMC_SIMRT_FMI_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/fmi/*.h)

## This should be set. The reason it is not now is because there is a cyclic dependency between
## gc/ and meta/ sources which are part of two different libraries at the moment. Either fix the
## code to remove the cyclic dependency or move meta/ sources out of libOpenModelicaRuntimeC and into libomcmemory
# set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} -Wl,--no-undefined")

# ######################################################################################################################
# Library: omcmemory
## This tiny library provides the memory related functionality of OM (garbage collection and memory_pool).
## The reason it is separated is because its functionality is clearly defined and should not be part of
## a bunch of other libraries. For example there is no need to link to OpenModelicaRuntimeC just to get GC
## functionality in Compiler/runtime.
add_library(omcmemory SHARED)
add_library(omc::simrt::memory ALIAS omcmemory)

target_sources(omcmemory PRIVATE ${OMC_SIMRT_GC_SOURCES})
target_link_libraries(omcmemory PUBLIC omc::3rd::omcgc)
target_include_directories(omcmemory PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

install(TARGETS omcmemory)

# ######################################################################################################################
# Library: OpenModelicaRuntimeC
add_library(OpenModelicaRuntimeC SHARED)
add_library(omc::simrt::runtime ALIAS OpenModelicaRuntimeC)

target_sources(OpenModelicaRuntimeC PRIVATE ${OMC_SIMRT_UTIL_SOURCES} ${OMC_SIMRT_META_SOURCES})
target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::simrt::memory)

if(WIN32)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC dbghelp)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC regex)
endif(WIN32)


install(TARGETS OpenModelicaRuntimeC)

# ######################################################################################################################
# Library: OpenModelicaFMIRuntimeC
## This library is built as a static library and contains everything needed to run an OpenModelica FMU.
## Therefore it has to include the functionality from the other libraries.
## It is not complete yet. I have to see what needs to go in here.
add_library(OpenModelicaFMIRuntimeC STATIC)
add_library(omc::simrt::fmiruntime ALIAS OpenModelicaFMIRuntimeC)

target_sources(OpenModelicaFMIRuntimeC PRIVATE ${OMC_SIMRT_FMI_SOURCES}
                                               $<TARGET_OBJECTS:OpenModelicaRuntimeC>
                                               $<TARGET_OBJECTS:omcmemory>)

target_link_libraries(OpenModelicaFMIRuntimeC PUBLIC omc::3rd::fmilib)

install(TARGETS OpenModelicaFMIRuntimeC)


# ######################################################################################################################
# Library: SimulationRuntimeC
add_library(SimulationRuntimeC SHARED)
add_library(omc::simrt::simruntime ALIAS SimulationRuntimeC)

target_sources(SimulationRuntimeC PRIVATE ${OMC_SIMRT_SIMULATION_SOURCES}
                                          ${OMC_SIMRT_MATH_SUPPORT_SOURCES}
                                          ${OMC_SIMRT_LINEARIZATION_SOURCES}
                                          ${OMC_SIMRT_DATA_RECONCILIATION_SOURCES})

target_link_libraries(SimulationRuntimeC PUBLIC omc::config)
target_link_libraries(SimulationRuntimeC PUBLIC omc::simrt::memory)
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

# Fix me. Make an interface (header only library) out of 3rdParty/dgesv
target_include_directories(SimulationRuntimeC PRIVATE ${OMCompiler_SOURCE_DIR}/3rdParty/dgesv/include/)

install(TARGETS SimulationRuntimeC)


# ######################################################################################################################
# Library: OptimizationRuntime
## This is now separated from SimulationRuntimeC. Just for clarity. It can be put back in there if needed.
## However having it as a separate lib will allow us to remove it based on an option. This means we can
## also remove the need for ipopt and mumps if this is disabled.
add_library(OptimizationRuntime SHARED)
add_library(omc::simrt::optimize ALIAS OptimizationRuntime)

target_sources(OptimizationRuntime PRIVATE ${OMC_SIMRT_OPTIMIZATION_SOURCES})

target_link_libraries(OptimizationRuntime PUBLIC omc::config)
target_link_libraries(OptimizationRuntime PUBLIC omc::simrt::memory)
target_link_libraries(OptimizationRuntime PUBLIC omc::simrt::simruntime)
target_link_libraries(OptimizationRuntime PUBLIC omc::3rd::ipopt)


install(TARGETS OptimizationRuntime)


# ######################################################################################################################
# Library: OpenModelicaSimulation
## This is a shared library containing everything needed for simulation. This is not intended to be used by the
## simulation executables. If something is needed for simulation executables add it here.
# add_library(OpenModelicaSimulation SHARED $<TARGET_OBJECTS:SimulationRuntimeC>
#                                           $<TARGET_OBJECTS:OpenModelicaRuntimeC>)
# add_library(omc::simrt::simulation ALIAS OpenModelicaSimulation)

# target_link_libraries(OpenModelicaSimulation PUBLIC
#                       $<TARGET_PROPERTY:SimulationRuntimeC,INTERFACE_LINK_LIBRARIES>)

# install(TARGETS OpenModelicaSimulation)


# ######################################################################################################################
## Install the header files. This installs the whole directory structure of c/ folder
## which means all headers will be installed keeping the directory structure intact.
## It might install some unneeded headers but it suffices for now.
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/omc
        FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.c.inc"
        PATTERN "build" EXCLUDE # To skip the build dir created by the normal Makefiles build system.
)




# ######################################################################################################################
# Quick and INCOMPLETE generation of RuntimeSources.mo
set(DGESV_FILES \"\")
set(LS_FILES \"\")
set(MIXED_FILES \"\")
set(NLS_FILESCMINPACK_FILES \"\")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo.cmake ${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo)
