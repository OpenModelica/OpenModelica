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

set(SOURCE_FMU_SOURCES_DIR ${CMAKE_INSTALL_DATAROOTDIR}/omc/sources/c)

set(SOURCE_FMU_COMMON_FILES_LIST gc/memory_pool.c gc/omc_gc.c util/base_array.c util/boolean_array.c util/division.c util/doubleEndedList.c util/generic_array.c util/index_spec.c util/integer_array.c util/jacobian_util.c util/list.c util/modelica_string_lit.c util/modelica_string.c util/ModelicaUtilities.c util/omc_error.c util/omc_file.c util/omc_init.c util/omc_mmap.c util/omc_msvc.c util/omc_numbers.c util/parallel_helper.c util/rational.c util/real_array.c util/ringbuffer.c util/simulation_options.c util/string_array.c util/utility.c util/varinfo.c math-support/pivot.c simulation/omc_simulation_util.c simulation/options.c simulation/simulation_info_json.c simulation/simulation_omc_assert.c simulation/solver/delay.c simulation/solver/fmi_events.c simulation/solver/model_help.c simulation/solver/omc_math.c simulation/solver/spatialDistribution.c simulation/solver/stateset.c simulation/solver/synchronous.c simulation/solver/initialization/initialization.c meta/meta_modelica_catch.c)

string(REPLACE ";" "," SOURCE_FMU_COMMON_FILES "${SOURCE_FMU_COMMON_FILES_LIST}")
foreach(source_file ${SOURCE_FMU_COMMON_FILES_LIST})
  list(APPEND SOURCE_FMU_COMMON_FILES_LIST_QUOTED \"${source_file}\")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file} DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR})
endforeach()
string(REPLACE ";" "," SOURCE_FMU_COMMON_FILES "${SOURCE_FMU_COMMON_FILES_LIST_QUOTED}")


set(SOURCE_FMU_COMMON_HEADERS \"./omc_inline.h\",\"./openmodelica_func.h\",\"./openmodelica.h\",\"./omc_simulation_settings.h\",\"./openmodelica_types.h\",\"./simulation_data.h\",\"./ModelicaUtilities.h\",\"./linearization/linearize.h\",\"./optimization/OptimizerData.h\",\"./optimization/OptimizerLocalFunction.h\",\"./optimization/OptimizerInterface.h\",\"./simulation/modelinfo.h\",\"./simulation/options.h\",\"./simulation/simulation_info_json.h\",\"./simulation/simulation_input_xml.h\",\"./simulation/simulation_runtime.h\",\"./simulation/omc_simulation_util.h\",\"./simulation/results/simulation_result.h\",\"./simulation/solver/cvode_solver.h\",\"./simulation/solver/dae_mode.h\",\"./simulation/solver/dassl.h\",\"./simulation/solver/delay.h\",\"./simulation/solver/embedded_server.h\",\"./simulation/solver/epsilon.h\",\"./simulation/solver/events.h\",\"./simulation/solver/external_input.h\",\"./simulation/solver/fmi_events.h\",\"./simulation/solver/ida_solver.h\",\"./simulation/solver/linearSolverLapack.h\",\"./simulation/solver/linearSolverTotalPivot.h\",\"./simulation/solver/linearSystem.h\",\"./simulation/solver/mixedSearchSolver.h\",\"./simulation/solver/mixedSystem.h\",\"./simulation/solver/model_help.h\",\"./simulation/solver/nonlinearSolverHomotopy.h\",\"./simulation/solver/nonlinearSolverHybrd.h\",\"./simulation/solver/nonlinearSystem.h\",\"./simulation/solver/nonlinearValuesList.h\",\"./simulation/solver/omc_math.h\",\"./simulation/solver/perform_qss_simulation.c.inc\",\"./simulation/solver/perform_simulation.c.inc\",\"./simulation/solver/real_time_sync.h\",\"./simulation/solver/solver_main.h\",\"./simulation/solver/spatialDistribution.h\",\"./simulation/solver/stateset.h\",\"./simulation/solver/sundials_error.h\",\"./simulation/solver/synchronous.h\",\"./simulation/solver/initialization/initialization.h\",\"./meta/meta_modelica_builtin_boxptr.h\",\"./meta/meta_modelica_builtin_boxvar.h\",\"./meta/meta_modelica_builtin.h\",\"./meta/meta_modelica.h\",\"./meta/meta_modelica_data.h\",\"./meta/meta_modelica_mk_box.h\",\"./meta/meta_modelica_segv.h\",\"./gc/omc_gc.h\",\"./gc/memory_pool.h\",\"./util/base_array.h\",\"./util/boolean_array.h\",\"./util/division.h\",\"./util/generic_array.h\",\"./util/index_spec.h\",\"./util/integer_array.h\",\"./util/jacobian_util.h\",\"./util/java_interface.h\",\"./util/modelica.h\",\"./util/modelica_string.h\",\"./util/omc_error.h\",\"./util/omc_file.h\",\"./util/omc_mmap.h\",\"./util/omc_msvc.h\",\"./util/omc_numbers.h\",\"./util/omc_spinlock.h\",\"./util/parallel_helper.h\",\"./util/read_matlab4.h\",\"./util/read_csv.h\",\"./util/libcsv.h\",\"./util/read_write.h\",\"./util/real_array.h\",\"./util/ringbuffer.h\",\"./util/rtclock.h\",\"./util/simulation_options.h\",\"./util/string_array.h\",\"./util/uthash.h\",\"./util/utility.h\",\"./util/varinfo.h\",\"./util/list.h\",\"./util/doubleEndedList.h\",\"./util/rational.h\",\"./util/modelica_string_lit.h\",\"./util/omc_init.h\",\"./dataReconciliation/dataReconciliation.h\")

set(DGESV_FILES \"\")
set(LS_FILES \"\")
set(MIXED_FILES \"\")
set(NLS_FILESCMINPACK_FILES \"\")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo.cmake ${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo)
