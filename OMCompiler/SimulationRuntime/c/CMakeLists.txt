cmake_minimum_required(VERSION 3.14)

project(OpenModelicaSimulationRuntimeC LANGUAGES C CXX)

# ######################################################################################################################
# INTERFACE target
# Other targets can link to this interface to get the include path transitively.
add_library(OpenModelicaRuntimeCInterface INTERFACE)
add_library(omc::simrt::runtime::headers ALIAS OpenModelicaRuntimeCInterface)

set(OMC_SIMRT_PUBLIC_HEADERS
  ModelicaUtilities.h
  omc_inline.h
  omc_simulation_settings.h
  openmodelica.h
  openmodelica_func.h
  openmodelica_types.h
  simulation_data.h
)

target_include_directories(OpenModelicaRuntimeCInterface
  INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/gc
)

target_link_libraries(OpenModelicaRuntimeCInterface
  INTERFACE
    omc::3rd::omcgc
)

set_target_properties(OpenModelicaRuntimeCInterface PROPERTIES
  PUBLIC_HEADER "${OMC_SIMRT_PUBLIC_HEADERS}"
)

install(
  FILES ${OMC_SIMRT_PUBLIC_HEADERS}
  DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c
)

# ######################################################################################################################
# Library: OpenModelicaRuntimeC

add_subdirectory(gc)
add_subdirectory(meta)
add_subdirectory(util)

# For the moment, we build OpenModelicaRuntimeC as a static library with MSVC.
# It has some dll exporting issues in it that need to be resolved.
if(MSVC)
  add_library(OpenModelicaRuntimeC STATIC)
else()
  add_library(OpenModelicaRuntimeC SHARED)
endif()

add_library(omc::simrt::runtime ALIAS OpenModelicaRuntimeC)

target_link_libraries(OpenModelicaRuntimeC
  PUBLIC
    omc::simrt::runtime::gc
    omc::simrt::runtime::meta
    omc::simrt::runtime::util
)

# Add the define WIN32_LEAN_AND_MEAN to this lib and anything that links to it.
# The reason is that the define tells windows.h not to include winsock.h. We want
# to use winsock2.h in some 3rdParty libraries and the two can not be used simultaneously.
# winsock2.h is backwards compatible with winsock.h.
target_compile_definitions(OpenModelicaRuntimeC PUBLIC WIN32_LEAN_AND_MEAN)

target_link_libraries(OpenModelicaRuntimeC PUBLIC OMCPThreads::OMCPThreads)
target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::3rd::omcgc)
target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::simrt::runtime::headers)

if(MINGW)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC dbghelp)
  target_link_options(OpenModelicaRuntimeC PRIVATE  -Wl,--export-all-symbols)
elseif(MSVC)
  set_target_properties(OpenModelicaRuntimeC PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()

install(TARGETS OpenModelicaRuntimeC
  COMPONENT omc)


# ######################################################################################################################
# Library: SimulationRuntimeC

add_subdirectory(dataReconciliation)
add_subdirectory(linearization)
add_subdirectory(math-support)
if(OM_OMC_ENABLE_MOO)
  add_subdirectory(moo)
endif()
if(OM_OMC_ENABLE_OPTIMIZATION)
  add_subdirectory(optimization)
endif()
add_subdirectory(simulation)

add_library(SimulationRuntimeC SHARED)
add_library(omc::simrt::simruntime ALIAS SimulationRuntimeC)

target_link_libraries(SimulationRuntimeC
  PUBLIC
    omc::simrt::simruntime::dataReconciliation
    omc::simrt::simruntime::linearization
    omc::simrt::simruntime::math-support
    omc::simrt::simruntime::simulation
)
if(OM_OMC_ENABLE_MOO)
  target_link_libraries(SimulationRuntimeC
    PUBLIC
      omc::simrt::simruntime::moo
  )
endif()
if(OM_OMC_ENABLE_OPTIMIZATION)
  target_link_libraries(SimulationRuntimeC
    PUBLIC
      omc::simrt::simruntime::optimization
  )
endif()

if(WIN32)
  target_link_libraries(SimulationRuntimeC PUBLIC wsock32)
endif()

if(MINGW)
  target_link_options(SimulationRuntimeC PRIVATE  -Wl,--export-all-symbols)
elseif(MSVC)
  set_target_properties(SimulationRuntimeC PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif(MINGW)

if(OM_OMC_ENABLE_PRIMME)
  target_compile_definitions(SimulationRuntimeC PRIVATE OMC_HAVE_PRIMME)
  target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::primme)
endif()

target_include_directories(SimulationRuntimeC
  PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
)

install(TARGETS SimulationRuntimeC)


# ######################################################################################################################
# include the configuration for (source code) FMI runtime and generate RuntimeSources.mo
# This is separated into another file just for clarity. Once it is cleaned up and organized
# it can be brought back here.
include(cmake/source_code_fmu_config.cmake)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo.cmake ${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo)

# ######################################################################################################################
# Add C Simulation Runtime unit tests
# Build with target "ctestsuite-depends"
# Run test with ctest
add_subdirectory(
  ${CMAKE_SOURCE_DIR}/testsuite/CTest/SimulationRuntime/c
  ${CMAKE_BINARY_DIR}/testsuite/CTest/SimulationRuntime/c
  EXCLUDE_FROM_ALL
)
