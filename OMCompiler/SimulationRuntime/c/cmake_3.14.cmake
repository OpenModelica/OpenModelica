cmake_minimum_required(VERSION 3.14)

find_package(LAPACK REQUIRED)

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

file(GLOB_RECURSE OMC_SIMRT_MOO_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/moo/*.cpp)
file(GLOB_RECURSE OMC_SIMRT_MOO_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/moo/*.h)


# ######################################################################################################################
# Library: OpenModelicaRuntimeC
# For the moment, we build OpenModelicaRuntimeC as a static library with MSVC.
# It has some dll exporting issues in it that need to be resolved.
if(MSVC)
  add_library(OpenModelicaRuntimeC STATIC)
else()
  add_library(OpenModelicaRuntimeC SHARED)
endif()

add_library(omc::simrt::runtime ALIAS OpenModelicaRuntimeC)

target_sources(OpenModelicaRuntimeC PRIVATE ${OMC_SIMRT_GC_SOURCES} ${OMC_SIMRT_UTIL_SOURCES} ${OMC_SIMRT_META_SOURCES})
target_include_directories(OpenModelicaRuntimeC
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/simulation
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/util)

# Add the define WIN32_LEAN_AND_MEAN to this lib and anything that links to it.
# The reason is that the define tells windows.h not to include winsock.h. We want
# to use winsock2.h in some 3rdParty libraries and the two can not be used simultaneously.
# winsock2.h is backwards compatible with winsock.h.
target_compile_definitions(OpenModelicaRuntimeC PUBLIC WIN32_LEAN_AND_MEAN)

target_link_libraries(OpenModelicaRuntimeC PUBLIC OMCPThreads::OMCPThreads)
target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::3rd::omcgc)
target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::3rd::ryu)

if(MINGW)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC dbghelp)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC regex)
  target_link_options(OpenModelicaRuntimeC PRIVATE  -Wl,--export-all-symbols)
elseif(MSVC)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::3rd::regex)
  set_target_properties(OpenModelicaRuntimeC PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()

install(TARGETS OpenModelicaRuntimeC
        COMPONENT omc)


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
target_link_libraries(SimulationRuntimeC PUBLIC ${LAPACK_LIBRARIES})

if(WIN32)
  target_link_libraries(SimulationRuntimeC PUBLIC wsock32)
endif()

if(MINGW)
  target_link_options(SimulationRuntimeC PRIVATE  -Wl,--export-all-symbols)
elseif(MSVC)
  set_target_properties(SimulationRuntimeC PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif(MINGW)

if(OM_OMC_ENABLE_IPOPT)
  target_sources(SimulationRuntimeC PRIVATE ${OMC_SIMRT_OPTIMIZATION_SOURCES})
  target_compile_definitions(SimulationRuntimeC PRIVATE OMC_HAVE_IPOPT)
  target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::ipopt)
endif()

if(OM_OMC_ENABLE_MOO)
  target_sources(SimulationRuntimeC PRIVATE ${OMC_SIMRT_MOO_SOURCES})
  target_compile_definitions(SimulationRuntimeC PRIVATE OMC_HAVE_MOO)
  target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::moo)
endif()

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

# ######################################################################################################################
## Enable testing in testsuite/CTest/SimulationRuntime/c. This means you need to be in
## <build_dir>/testsuite/CTest/SimulationRuntime/c folder to run ctest.
## If you want to run the tests while in another directory (ctest > 3.22) you
## have to specify --test-dir (e.g., ctest --test-dir build_cmake/testsuite/CTest/SimulationRuntime/c )
add_subdirectory(${CMAKE_SOURCE_DIR}/testsuite/CTest/SimulationRuntime/c ${CMAKE_BINARY_DIR}/testsuite/CTest/SimulationRuntime/c)
