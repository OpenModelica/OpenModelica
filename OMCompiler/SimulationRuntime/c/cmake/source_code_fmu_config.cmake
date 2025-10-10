# ######################################################################################################################
## Generation of RuntimeSources.mo for source code FMU handling.

## This is still a bit too confusing. I have tried to make it a bit cleaner by following conventions, naming variables properly,
## being as consistent as possible. However, it can still use some improvments. Unfortunatelly modifying things even more requrires
## modifications to the Makefile build system and much more. So for now this is deemed enough. Hopefully once the CMake config is
## "finished" we can come back to this and modify things as freely as we want.

## This is where the CMake config expects sources related to source-code-fmus. This will normally be <install_dir>/share/omc/sources/c
set(SOURCE_FMU_SOURCES_DIR ${CMAKE_INSTALL_DATAROOTDIR}/omc/sources/c)



######################################################################################################################
# Common source files for all source-code-FMUs
set(SOURCE_FMU_COMMON_FILES_LIST ./gc/memory_pool.c
                                 ./gc/omc_gc.c
                                 ./util/base_array.c
                                 ./util/boolean_array.c
                                 ./util/context.c
                                 ./util/division.c
                                 ./util/doubleEndedList.c
                                 ./util/generic_array.c
                                 ./util/index_spec.c
                                 ./util/integer_array.c
                                 ./util/list.c
                                 ./util/modelica_string_lit.c
                                 ./util/modelica_string.c
                                 ./util/ModelicaUtilities.c
                                 ./util/omc_error.c
                                 ./util/omc_file.c
                                 ./util/omc_init.c
                                 ./util/omc_mmap.c
                                 ./util/omc_msvc.c
                                 ./util/omc_numbers.c
                                 ./util/parallel_helper.c
                                 ./util/rational.c
                                 ./util/real_array.c
                                 ./util/ringbuffer.c
                                 ./util/simulation_options.c
                                 ./util/string_array.c
                                 ./util/utility.c
                                 ./util/varinfo.c
                                 ./math-support/pivot.c
                                 ./simulation/arrayIndex.c
                                 ./simulation/jacobian_util.c
                                 ./simulation/omc_simulation_util.c
                                 ./simulation/options.c
                                 ./simulation/simulation_info_json.c
                                 ./simulation/simulation_omc_assert.c
                                 ./simulation/solver/delay.c
                                 ./simulation/solver/fmi_events.c
                                 ./simulation/solver/model_help.c
                                 ./simulation/solver/omc_math.c
                                 ./simulation/solver/spatialDistribution.c
                                 ./simulation/solver/stateset.c
                                 ./simulation/solver/synchronous.c
                                 ./simulation/solver/initialization/initialization.c
                                 ./meta/meta_modelica_catch.c)

# Install the files keeping the folder structure. While also created a quoted string list for use by MM code.
foreach(source_file ${SOURCE_FMU_COMMON_FILES_LIST})
  list(APPEND SOURCE_FMU_COMMON_FILES_LIST_QUOTED \"${source_file}\")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.20")
    set(SOURCE_FMU_SOURCES_DEST_DIR "${SOURCE_FMU_SOURCES_DIR}")
    cmake_path(APPEND SOURCE_FMU_SOURCES_DEST_DIR "${DEST_DIR}")
    cmake_path(NORMAL_PATH SOURCE_FMU_SOURCES_DEST_DIR)
  else()
    set(SOURCE_FMU_SOURCES_DEST_DIR "${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR}")
  endif()

  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DEST_DIR}
          COMPONENT fmu)
endforeach()
string(REPLACE ";" ",\n                                         " SOURCE_FMU_COMMON_FILES "${SOURCE_FMU_COMMON_FILES_LIST_QUOTED}")


set(SOURCE_FMU_COMMON_HEADERS \"./omc_inline.h\",
                              \"./openmodelica_func.h\",
                              \"./openmodelica.h\",
                              \"./omc_simulation_settings.h\",
                              \"./openmodelica_types.h\",
                              \"./simulation_data.h\",
                              \"./ModelicaUtilities.h\",
                              \"./linearization/linearize.h\",
                              \"./optimization/OptimizerData.h\",
                              \"./optimization/OptimizerLocalFunction.h\",
                              \"./optimization/OptimizerInterface.h\",
                              \"./simulation/arrayIndex.h\",
                              \"./simulation/jacobian_util.h\",
                              \"./simulation/modelinfo.h\",
                              \"./simulation/options.h\",
                              \"./simulation/simulation_info_json.h\",
                              \"./simulation/simulation_input_xml.h\",
                              \"./simulation/simulation_omc_assert.h\",
                              \"./simulation/simulation_runtime.h\",
                              \"./simulation/omc_simulation_util.h\",
                              \"./simulation/results/simulation_result.h\",
                              \"./simulation/solver/cvode_solver.h\",
                              \"./simulation/solver/dae_mode.h\",
                              \"./simulation/solver/dassl.h\",
                              \"./simulation/solver/delay.h\",
                              \"./simulation/solver/embedded_server.h\",
                              \"./simulation/solver/epsilon.h\",
                              \"./simulation/solver/events.h\",
                              \"./simulation/solver/external_input.h\",
                              \"./simulation/solver/fmi_events.h\",
                              \"./simulation/solver/ida_solver.h\",
                              \"./simulation/solver/linearSolverLapack.h\",
                              \"./simulation/solver/linearSolverTotalPivot.h\",
                              \"./simulation/solver/linearSystem.h\",
                              \"./simulation/solver/mixedSearchSolver.h\",
                              \"./simulation/solver/mixedSystem.h\",
                              \"./simulation/solver/model_help.h\",
                              \"./simulation/solver/nonlinearSolverHomotopy.h\",
                              \"./simulation/solver/nonlinearSolverHybrd.h\",
                              \"./simulation/solver/nonlinearSystem.h\",
                              \"./simulation/solver/nonlinearValuesList.h\",
                              \"./simulation/solver/omc_math.h\",
                              \"./simulation/solver/perform_qss_simulation.c.inc\",
                              \"./simulation/solver/perform_simulation.c.inc\",
                              \"./simulation/solver/real_time_sync.h\",
                              \"./simulation/solver/solver_main.h\",
                              \"./simulation/solver/spatialDistribution.h\",
                              \"./simulation/solver/stateset.h\",
                              \"./simulation/solver/sundials_error.h\",
                              \"./simulation/solver/sundials_util.h\",
                              \"./simulation/solver/synchronous.h\",
                              \"./simulation/solver/initialization/initialization.h\",
                              \"./meta/meta_modelica_builtin_boxptr.h\",
                              \"./meta/meta_modelica_builtin_boxvar.h\",
                              \"./meta/meta_modelica_builtin.h\",
                              \"./meta/meta_modelica.h\",
                              \"./meta/meta_modelica_data.h\",
                              \"./meta/meta_modelica_mk_box.h\",
                              \"./meta/meta_modelica_segv.h\",
                              \"./gc/omc_gc.h\",
                              \"./gc/memory_pool.h\",
                              \"./util/base_array.h\",
                              \"./util/boolean_array.h\",
                              \"./util/context.h\",
                              \"./util/division.h\",
                              \"./util/generic_array.h\",
                              \"./util/index_spec.h\",
                              \"./util/integer_array.h\",
                              \"./util/java_interface.h\",
                              \"./util/modelica.h\",
                              \"./util/modelica_string.h\",
                              \"./util/omc_error.h\",
                              \"./util/omc_file.h\",
                              \"./util/omc_mmap.h\",
                              \"./util/omc_msvc.h\",
                              \"./util/omc_numbers.h\",
                              \"./util/omc_spinlock.h\",
                              \"./util/parallel_helper.h\",
                              \"./util/read_matlab4.h\",
                              \"./util/read_csv.h\",
                              \"./util/libcsv.h\",
                              \"./util/read_write.h\",
                              \"./util/real_array.h\",
                              \"./util/ringbuffer.h\",
                              \"./util/rtclock.h\",
                              \"./util/simulation_options.h\",
                              \"./util/string_array.h\",
                              \"./util/uthash.h\",
                              \"./util/utility.h\",
                              \"./util/varinfo.h\",
                              \"./util/list.h\",
                              \"./util/doubleEndedList.h\",
                              \"./util/rational.h\",
                              \"./util/modelica_string_lit.h\",
                              \"./util/omc_init.h\",
                              \"./dataReconciliation/dataReconciliation.h\")

string(REPLACE ";" "\n                                         " SOURCE_FMU_COMMON_HEADERS "${SOURCE_FMU_COMMON_HEADERS}")


######################################################################################################################
# Lapack files
file(GLOB_RECURSE 3RD_DGESV_FILES   ${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/blas/*.c
                                    ${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/lapack/*.c
                                    ${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/libf2c/*.c)

file(GLOB_RECURSE 3RD_DGESV_HEADERS ${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/include/*.h)

install(FILES ${3RD_DGESV_HEADERS}
              ${3RD_DGESV_FILES}
        DESTINATION ${SOURCE_FMU_SOURCES_DIR}/external_solvers
        COMPONENT fmu
)

foreach(source_file_full_path ${3RD_DGESV_FILES})
  get_filename_component(source_file ${source_file_full_path} NAME)
  list(APPEND SOURCE_FMU_DGESV_FILES_LIST_QUOTED \"./external_solvers/${source_file}\")
endforeach()
string(REPLACE ";" "," SOURCE_FMU_DGESV_FILES "${SOURCE_FMU_DGESV_FILES_LIST_QUOTED}")


######################################################################################################################
## Non-linear system files

set(SOURCE_FMU_NLS_FILES_LIST simulation/solver/nonlinearSolverHomotopy.c simulation/solver/nonlinearSolverHybrd.c simulation/solver/nonlinearValuesList.c simulation/solver/nonlinearSystem.c)

foreach(source_file ${SOURCE_FMU_NLS_FILES_LIST})
  list(APPEND SOURCE_FMU_NLS_FILES_LIST_QUOTED \"${source_file}\")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR}
          COMPONENT fmu)
endforeach()
string(REPLACE ";" "," SOURCE_FMU_NLS_FILES "${SOURCE_FMU_NLS_FILES_LIST_QUOTED}")


# CMinPack files for NLS
set(3RD_CMINPACK_FMU_FILES ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/cminpack.h
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/minpack.h
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/enorm_.c
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/hybrj_.c
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/dpmpar_.c
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/qrfac_.c
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/qform_.c
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/dogleg_.c
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/r1updt_.c
                            ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/r1mpyq_.c)

set(3RD_CMINPACK_HEADERS  ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/cminpack.h
                          ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/minpack.h
                          ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/minpackP.h)

install(FILES ${3RD_CMINPACK_HEADERS}
              ${3RD_CMINPACK_FMU_FILES}
        DESTINATION ${SOURCE_FMU_SOURCES_DIR}/external_solvers
        COMPONENT fmu
)

foreach(source_file_full_path ${3RD_CMINPACK_FMU_FILES})
  get_filename_component(source_file ${source_file_full_path} NAME)
  list(APPEND SOURCE_FMU_CMINPACK_FILES_LIST_QUOTED \"./external_solvers/${source_file}\")
endforeach()
string(REPLACE ";" "," SOURCE_FMU_CMINPACK_FILES "${SOURCE_FMU_CMINPACK_FILES_LIST_QUOTED}")



######################################################################################################################
## Linear system files
set(SOURCE_FMU_LS_FILES_LIST simulation/solver/linearSystem.c simulation/solver/linearSolverLapack.c simulation/solver/linearSolverTotalPivot.c)

foreach(source_file ${SOURCE_FMU_LS_FILES_LIST})
  list(APPEND SOURCE_FMU_LS_FILES_LIST_QUOTED \"${source_file}\")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR}
          COMPONENT fmu)
endforeach()
string(REPLACE ";" "," SOURCE_FMU_LS_FILES "${SOURCE_FMU_LS_FILES_LIST_QUOTED}")


######################################################################################################################
## Mixed system files
set(SOURCE_FMU_MIXED_FILES_LIST simulation/solver/mixedSearchSolver.c simulation/solver/mixedSystem.c)

foreach(source_file ${SOURCE_FMU_MIXED_FILES_LIST})
  list(APPEND SOURCE_FMU_MIXED_FILES_LIST_QUOTED \"${source_file}\")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR}
          COMPONENT fmu)
endforeach()
string(REPLACE ";" "," SOURCE_FMU_MIXED_FILES "${SOURCE_FMU_MIXED_FILES_LIST_QUOTED}")



######################################################################################################################
## CVODE files
set(SOURCE_FMU_CVODE_RUNTIME_FILES_LIST simulation/solver/cvode_solver.c simulation/solver/sundials_error.c)

foreach(source_file ${SOURCE_FMU_CVODE_RUNTIME_FILES_LIST})
  list(APPEND SOURCE_FMU_CVODE_RUNTIME_FILES_LIST_QUOTED \"${source_file}\")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR}
          COMPONENT fmu)
endforeach()
string(REPLACE ";" "," SOURCE_FMU_CVODE_RUNTIME_FILES "${SOURCE_FMU_CVODE_RUNTIME_FILES_LIST_QUOTED}")






# ######################################################################################################################
# Library: SimulationRuntimeFMI
add_library(SimulationRuntimeFMI STATIC)
add_library(omc::simrt::simrtfmi ALIAS SimulationRuntimeFMI)

target_sources(SimulationRuntimeFMI PRIVATE ${SOURCE_FMU_COMMON_FILES_LIST}
                                            ${SOURCE_FMU_LS_FILES_LIST}
                                            ${SOURCE_FMU_NLS_FILES_LIST}
                                            ${SOURCE_FMU_MIXED_FILES_LIST}
                                            ${3RD_CMINPACK_FMU_FILES})

target_compile_definitions(SimulationRuntimeFMI PRIVATE OMC_MINIMAL_RUNTIME=1;OMC_FMI_RUNTIME=1;CMINPACK_NO_DLL)

target_include_directories(SimulationRuntimeFMI PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(SimulationRuntimeFMI PUBLIC OMCPThreads::OMCPThreads)

install(TARGETS SimulationRuntimeFMI
        COMPONENT fmu)


# ######################################################################################################################
# Library: OpenModelicaFMIRuntimeC

file(GLOB OMC_SIMRT_FMI_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/fmi/*.c)
file(GLOB OMC_SIMRT_FMI_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/fmi/*.h)

add_library(OpenModelicaFMIRuntimeC STATIC)
add_library(omc::simrt::fmiruntime ALIAS OpenModelicaFMIRuntimeC)

target_sources(OpenModelicaFMIRuntimeC PRIVATE ${OMC_SIMRT_FMI_SOURCES})

# target_link_libraries(OpenModelicaFMIRuntimeC_base PUBLIC omc::config)
target_link_libraries(OpenModelicaFMIRuntimeC PUBLIC omc::3rd::fmilib)

install(TARGETS OpenModelicaFMIRuntimeC
        COMPONENT fmu)
