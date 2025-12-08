cmake_minimum_required(VERSION 3.14)

find_package(LAPACK REQUIRED)

# Define sources with a recursive glob
file(GLOB_RECURSE OMC_SIMRT_SIMULATION_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.c
                                               ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
file(GLOB_RECURSE OMC_SIMRT_SIMULATION_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

add_library(OpenModelicaRuntimeCSimulation OBJECT ${OMC_SIMRT_SIMULATION_SOURCES})
add_library(omc::simrt::simruntime::simulation ALIAS OpenModelicaRuntimeCSimulation)

target_include_directories(OpenModelicaRuntimeCSimulation
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>/results
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>/solver
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>/solver/initialization

    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/simulation>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/simulation/results>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/simulation/solver>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}/c/simulation/solver/initialization>
)

target_link_libraries(OpenModelicaRuntimeCSimulation
  PUBLIC
    omc::config
    omc::simrt::runtime
    omc::simrt::runtime::headers
    omc::3rd::FMIL::expat
    omc::3rd::sundials::cvode
    omc::3rd::sundials::idas
    omc::3rd::sundials::kinsol
    omc::3rd::sundials::sunlinsolklu
    omc::3rd::sundials::sunlinsollapackdense
    omc::3rd::suitesparse::klu
    omc::3rd::suitesparse::amd
    omc::3rd::suitesparse::btf
    omc::3rd::suitesparse::colamd
    omc::3rd::suitesparse::umfpack
    omc::3rd::suitesparse::config
    omc::3rd::cminpack
    omc::3rd::cdaskr
    omc::3rd::lis
    ${LAPACK_LIBRARIES}
)

if(OM_OMC_ENABLE_OPTIMIZATION)
  target_link_libraries(OpenModelicaRuntimeCSimulation
    PUBLIC
      omc::simrt::simruntime::optimization)
endif()

if(OM_OMC_ENABLE_MOO)
  target_link_libraries(OpenModelicaRuntimeCSimulation
    PUBLIC
      omc::simrt::simruntime::moo)
endif()

if(MINGW)
  target_link_libraries(OpenModelicaRuntimeCSimulation PUBLIC regex)
elseif(MSVC)
  target_link_libraries(OpenModelicaRuntimeCSimulation PUBLIC omc::3rd::regex)
endif()

# Install the header files.
# This installs the whole directory structure of simulation/ folder which means
# all headers will be installed keeping the directory structure intact. It might
# install some unneeded headers but it suffices for now.
install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c
  FILES_MATCHING
    PATTERN "*.h"
    PATTERN "*.c.inc"
)
