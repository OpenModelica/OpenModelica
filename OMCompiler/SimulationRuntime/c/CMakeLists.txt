cmake_minimum_required(VERSION 3.14)

project(OpenModelicaSimulationRuntimeC LANGUAGES C CXX)

### Standards ###############################################################################################
## Set the C standard to use.
set(C_STANDARD C17)
set(C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS OFF)

## Enforce standards as strictly as possible
if(NOT MSVC)
  add_compile_options(-Wpedantic -pedantic-errors)
  # Clang puts designated-initializer warnings under -Werror=c23-extensions and
  # -Wc++20-extensions / -Wc++23-extensions (warning-level, not
  # extension-level), so -pedantic-errors alone does not promote them to errors.
  if(CMAKE_C_COMPILER_ID MATCHES "Clang")
    add_compile_options("$<$<COMPILE_LANGUAGE:C>:-Werror=c23-extensions>")
  endif ()
  if(CMAKE_CXX_COMPILER_ID MATCHES "Clang")
    add_compile_options(
      "$<$<COMPILE_LANGUAGE:CXX>:-Werror=c++20-extensions>"
      "$<$<COMPILE_LANGUAGE:CXX>:-Werror=c++23-extensions>"
    )
  endif()
endif()

# Coverage instrumentation (-DOM_ENABLE_COVERAGE=ON), applied directory-wide so
# every target defined here and in every add_subdirectory() below is covered.
# See cmake/modules/OpenModelicaCoverage.cmake.
if(OM_ENABLE_COVERAGE)
  add_compile_options(${OM_COVERAGE_COMPILE_OPTIONS})
  add_link_options(--coverage)
endif()

# ######################################################################################################################
# INTERFACE target
# Other targets can link to this interface to get the include path transitively.
add_library(OpenModelicaRuntimeCInterface INTERFACE)
add_library(omc::simrt::runtime::headers ALIAS OpenModelicaRuntimeCInterface)

set(OMC_SIMRT_PUBLIC_HEADERS
  "ModelicaUtilities.h"
  "omc_dll.h"
  "omc_inline.h"
  "omc_simulation_settings.h"
  "openmodelica_func.h"
  "openmodelica_types.h"
  "openmodelica.h"
  "simulation_data.h"
)

target_include_directories(OpenModelicaRuntimeCInterface
  INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/gc
)

# The headers need pthreads: threadData_t holds a pthread_mutex_t.
target_link_libraries(OpenModelicaRuntimeCInterface
  INTERFACE
    OMCPThreads::OMCPThreads
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

# Static with MSVC: as its own DLL every global it shares with
# SimulationRuntimeC would cross a DLL boundary, and the consumers inside this
# project are not compiled with IMPORT_INTO.
if(MSVC)
  add_library(OpenModelicaRuntimeC STATIC)
else()
  add_library(OpenModelicaRuntimeC SHARED)
endif()

add_library(omc::simrt::runtime ALIAS OpenModelicaRuntimeC)

# meta/ belongs to libOpenModelicaRuntimeMMC only.
target_link_libraries(OpenModelicaRuntimeC
  PUBLIC
    omc::simrt::runtime::gc
    omc::simrt::runtime::util
)

# Add the define WIN32_LEAN_AND_MEAN to this lib and anything that links to it.
# The reason is that the define tells windows.h not to include winsock.h. We want
# to use winsock2.h in some 3rdParty libraries and the two can not be used simultaneously.
# winsock2.h is backwards compatible with winsock.h.
target_compile_definitions(OpenModelicaRuntimeC PUBLIC WIN32_LEAN_AND_MEAN)

target_link_libraries(OpenModelicaRuntimeC PUBLIC OMCPThreads::OMCPThreads)
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
# Library: SimulationRuntimeC (--simCodeTarget=C.old). The subdirectories install
# their headers either way; the code --simCodeTarget=C generates includes them too.

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

if(OM_OMC_ENABLE_C_OLD_RUNTIME)
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
    # WINDOWS_EXPORT_ALL_SYMBOLS only scans the target's own objects, so the
    # static OpenModelicaRuntimeC's symbols would sit
    # in the DLL unexported. Put those objects in it directly.
    target_sources(SimulationRuntimeC PRIVATE
      $<TARGET_OBJECTS:OpenModelicaRuntimeCUtil>
      $<TARGET_OBJECTS:OpenModelicaRuntimeCGC>)
  endif(MINGW)

  if(OM_OMC_ENABLE_COLPACK)
    target_compile_definitions(SimulationRuntimeC PRIVATE OMC_HAVE_COLPACK)
    target_link_libraries(SimulationRuntimeC PUBLIC omc::3rd::colpack)
  endif()

  target_include_directories(SimulationRuntimeC
    PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}
  )

  install(TARGETS SimulationRuntimeC)
endif()


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
# They live in testsuite/, so they follow OM_ENABLE_TESTSUITE (see the top-level CMakeLists.txt).
if(OM_ENABLE_TESTSUITE AND OM_OMC_ENABLE_C_OLD_RUNTIME)
  add_subdirectory(
    ${CMAKE_SOURCE_DIR}/testsuite/CTest/SimulationRuntime/c
    ${CMAKE_BINARY_DIR}/testsuite/CTest/SimulationRuntime/c
    EXCLUDE_FROM_ALL
  )
endif()
