# ######################################################################################################################
## Generation of RuntimeSources.mo for source code FMU handling.

## This is still a bit too confusing. I have tried to make it a bit cleaner by following conventions, naming variables properly,
## being as consistent as possible. However, it can still use some improvments. Unfortunatelly modifying things even more requrires
## modifications to the Makefile build system and much more. So for now this is deemed enough. Hopefully once the CMake config is
## "finished" we can come back to this and modify things as freely as we want.

## This is where the CMake config expects sources related to source-code-fmus. This will normally be <install_dir>/share/omc/sources/c
set(SOURCE_FMU_SOURCES_DIR ${CMAKE_INSTALL_DATAROOTDIR}/omc/sources/c)

## Where SimulationRuntime/rust/CMakeLists.txt installs the crates a
## --simCodeTarget=C+Rust source FMU carries.
set(SOURCE_FMU_RUST_SOURCES_DIR ${CMAKE_INSTALL_DATAROOTDIR}/omc/sources/rust)



######################################################################################################################
# Common source files for all source-code-FMUs.
#
# Two lists, split along the same line the two runtime libraries are split along:
# what libOpenModelicaRuntimeC covers (gc/, meta/, util/) and what
# libSimulationRuntimeC covers (simulation/, math-support/). A source FMU built
# with --simCodeTarget=C+Rust ships only the first, and links the Rust runtime for
# the second. See Compiler/SimCode/SimCodeMain.mo.
set(SOURCE_FMU_RUNTIME_C_FILES_LIST "gc/omc_alloc.c"
                                    "gc/omc_rc.c"
                                    "gc/omc_gc.c"
                                    "util/base_array.c"
                                    "util/boolean_array.c"
                                    "util/context.c"
                                    "util/division.c"
                                    "util/doubleEndedList.c"
                                    "util/generic_array.c"
                                    "util/index_spec.c"
                                    "util/integer_array.c"
                                    "util/list.c"
                                    "util/modelica_string_lit.c"
                                    "util/modelica_string.c"
                                    "util/ModelicaUtilities.c"
                                    "util/omc_error.c"
                                    "util/omc_file.c"
                                    "util/omc_init.c"
                                    "util/omc_mmap.c"
                                    "util/omc_msvc.c"
                                    "util/omc_numbers.c"
                                    "util/omc_box.c"
                                    # No omc_stackoverflow.c: the minimal runtime inlines it.
                                    "util/omc_str_utils.c"
                                    "util/omc_string.c"
                                    "util/rational.c"
                                    "util/real_array.c"
                                    "util/ringbuffer.c"
                                    "util/simulation_options.c"
                                    "util/string_array.c"
                                    "util/utility.c"
                                    "util/varinfo.c"
                                    "meta/meta_modelica_catch.c")

set(SOURCE_FMU_SIMRT_C_FILES_LIST "math-support/pivot.c"
                                  "simulation/arrayIndex.c"
                                  "simulation/eval_dep.c"
                                  # jacobian_colpack.cpp is deliberately not here, the same
                                  # as in Makefile.objs SIM_OBJS_C: all of it is behind
                                  # OMC_HAVE_COLPACK, which an FMU does not define and could
                                  # not satisfy anyway, shipping neither ColPack's headers nor
                                  # the library. jacobian_colpack.h stays, jacobian_util.c
                                  # includes it unconditionally.
                                  "simulation/jacobian_util.c"
                                  "simulation/omc_simulation_util.c"
                                  "simulation/options.c"
                                  "simulation/simulation_info_json.c"
                                  "simulation/simulation_omc_assert.c"
                                  "simulation/solver/delay.c"
                                  "simulation/solver/discrete_changes.c"
                                  "simulation/solver/model_help.c"
                                  "simulation/solver/omc_math.c"
                                  "simulation/solver/spatialDistribution.c"
                                  "simulation/solver/stateset.c"
                                  "simulation/solver/synchronous.c"
                                  "simulation/solver/initialization/initialization.c")

set(SOURCE_FMU_COMMON_FILES_LIST ${SOURCE_FMU_RUNTIME_C_FILES_LIST}
                                 ${SOURCE_FMU_SIMRT_C_FILES_LIST})

# Install the files keeping the folder structure. While also created a quoted string list for use by MM code.
foreach(source_file ${SOURCE_FMU_COMMON_FILES_LIST})
  list(APPEND SOURCE_FMU_COMMON_FILES_LIST_QUOTED "\"${source_file}\"")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.20")
    set(SOURCE_FMU_SOURCES_DEST_DIR "${SOURCE_FMU_SOURCES_DIR}")
    cmake_path(APPEND SOURCE_FMU_SOURCES_DEST_DIR "${DEST_DIR}")
    cmake_path(NORMAL_PATH SOURCE_FMU_SOURCES_DEST_DIR)
  else()
    set(SOURCE_FMU_SOURCES_DEST_DIR "${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR}")
  endif()

  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DEST_DIR})
endforeach()
list(JOIN SOURCE_FMU_COMMON_FILES_LIST_QUOTED ",\n                                         " SOURCE_FMU_COMMON_FILES)

foreach(source_file ${SOURCE_FMU_RUNTIME_C_FILES_LIST})
  list(APPEND SOURCE_FMU_RUNTIME_C_FILES_LIST_QUOTED "\"${source_file}\"")
endforeach()
list(JOIN SOURCE_FMU_RUNTIME_C_FILES_LIST_QUOTED ",\n                                              " SOURCE_FMU_RUNTIME_C_FILES)


set(SOURCE_FMU_COMMON_HEADERS "omc_dll.h"
                              "omc_inline.h"
                              "openmodelica_func.h"
                              "openmodelica.h"
                              "omc_simulation_settings.h"
                              "openmodelica_types.h"
                              "simulation_data.h"
                              "ModelicaUtilities.h"
                              "linearization/linearize.h"
                              "simulation/arrayIndex.h"
                              "simulation/eval_dep.h"
                              "simulation/jacobian_colpack.h"
                              "simulation/jacobian_util.h"
                              "simulation/modelinfo.h"
                              "simulation/options.h"
                              "simulation/simulation_info_json.h"
                              "simulation/simulation_input_xml.h"
                              "simulation/simulation_omc_assert.h"
                              "simulation/simulation_runtime.h"
                              "simulation/omc_simulation_util.h"
                              "simulation/results/simulation_result.h"
                              "simulation/solver/cvode_solver.h"
                              "simulation/solver/dae_mode.h"
                              "simulation/solver/dassl.h"
                              "simulation/solver/delay.h"
                              "simulation/solver/embedded_server.h"
                              "simulation/solver/epsilon.h"
                              "simulation/solver/events.h"
                              "simulation/solver/external_input.h"
                              "simulation/solver/discrete_changes.h"
                              "simulation/solver/ida_solver.h"
                              "simulation/solver/linearSolverLapack.h"
                              "simulation/solver/linearSolverTotalPivot.h"
                              "simulation/solver/linearSystem.h"
                              "simulation/solver/mixedSearchSolver.h"
                              "simulation/solver/mixedSystem.h"
                              "simulation/solver/model_help.h"
                              "simulation/solver/nonlinearSolverHomotopy.h"
                              "simulation/solver/nonlinearSolverHybrd.h"
                              "simulation/solver/nonlinearSystem.h"
                              "simulation/solver/nonlinearValuesList.h"
                              "simulation/solver/omc_math.h"
                              "simulation/solver/perform_qss_simulation.c.inc"
                              "simulation/solver/perform_simulation.c.inc"
                              "simulation/solver/real_time_sync.h"
                              "simulation/solver/solver_main.h"
                              "simulation/solver/spatialDistribution.h"
                              "simulation/solver/stateset.h"
                              "simulation/solver/sundials_error.h"
                              "simulation/solver/sundials_util.h"
                              "simulation/solver/synchronous.h"
                              "simulation/solver/initialization/initialization.h"
                              "meta/meta_modelica_builtin_boxptr.h"
                              "meta/meta_modelica_builtin_boxvar.h"
                              "meta/meta_modelica_builtin.h"
                              "meta/meta_modelica.h"
                              "meta/meta_modelica_data.h"
                              "meta/meta_modelica_mk_box.h"
                              "meta/meta_modelica_segv.h"
                              "gc/omc_alloc.h"
                              "gc/omc_gc.h"
                              "gc/omc_rc.h"
                              "util/base_array.h"
                              "util/boolean_array.h"
                              "util/context.h"
                              "util/division.h"
                              "util/generic_array.h"
                              "util/index_spec.h"
                              "util/integer_array.h"
                              "util/ModelicaUtilitiesExtra.h"
                              "util/modelica.h"
                              "util/modelica_string.h"
                              "util/omc_error.h"
                              "util/omc_file.h"
                              "util/omc_mmap.h"
                              "util/omc_msvc.h"
                              "util/omc_numbers.h"
                              "util/omc_box.h"
                              "util/omc_stackoverflow.h"
                              "util/omc_str_utils.h"
                              "util/omc_string.h"
                              "util/omc_spinlock.h"
                              "util/omc_strdup.h"
                              "util/read_matlab4.h"
                              "util/read_csv.h"
                              "util/libcsv.h"
                              "util/read_write.h"
                              "util/real_array.h"
                              "util/ringbuffer.h"
                              "util/rtclock.h"
                              "util/simulation_options.h"
                              "util/string_array.h"
                              "util/uthash.h"
                              "util/utility.h"
                              "util/varinfo.h"
                              "util/list.h"
                              "util/doubleEndedList.h"
                              "util/rational.h"
                              "util/modelica_string_lit.h"
                              "util/omc_init.h"
                              "dataReconciliation/dataReconciliation.h")

set(SOURCE_FMU_COMMON_QUOTED_HEADERS)
foreach(source_file IN LISTS SOURCE_FMU_COMMON_HEADERS)
  list(APPEND SOURCE_FMU_COMMON_QUOTED_HEADERS "\"${source_file}\"")
endforeach()
list(JOIN SOURCE_FMU_COMMON_QUOTED_HEADERS ",\n                                         " SOURCE_FMU_COMMON_HEADERS)

######################################################################################################################
# Lapack files
file(GLOB_RECURSE 3RD_DGESV_FILES ${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/blas/*.c
                                  ${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/lapack/*.c
                                  ${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/libf2c/*.c)

# Not used by C runtime
list(REMOVE_ITEM 3RD_DGESV_FILES "${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/lapack/dgesc2.c"
                                 "${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/lapack/dgetc2.c"
                                 "${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/lapack/dlabad.c"
)

file(GLOB_RECURSE 3RD_DGESV_HEADERS ${OMCompiler_3rdParty_SOURCE_DIR}/dgesv/include/*.h)

install(FILES ${3RD_DGESV_HEADERS}
              ${3RD_DGESV_FILES}
        DESTINATION ${SOURCE_FMU_SOURCES_DIR}/external_solvers
)

foreach(source_file_full_path ${3RD_DGESV_FILES})
  get_filename_component(source_file ${source_file_full_path} NAME)
  list(APPEND SOURCE_FMU_DGESV_FILES_LIST_QUOTED "\"external_solvers/${source_file}\"")
endforeach()
list(JOIN SOURCE_FMU_DGESV_FILES_LIST_QUOTED ",\n                                       " SOURCE_FMU_DGESV_FILES)

######################################################################################################################
## Non-linear system files

set(SOURCE_FMU_NLS_FILES_LIST simulation/solver/nonlinearSolverHybrd.c
                              simulation/solver/nonlinearSystem.c
                              simulation/solver/nonlinearValuesList.c
                              simulation/solver/nonlinearSolverHomotopy.c)

foreach(source_file ${SOURCE_FMU_NLS_FILES_LIST})
  list(APPEND SOURCE_FMU_NLS_FILES_LIST_QUOTED "\"${source_file}\"")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR})
endforeach()
list(JOIN SOURCE_FMU_NLS_FILES_LIST_QUOTED ",\n                                         " SOURCE_FMU_NLS_FILES)


# CMinPack files for NLS
if (NOT OM_USE_SYSTEM_CMINPACK)
  set(3RD_CMINPACK_FMU_FILES ${OMCompiler_3rdParty_SOURCE_DIR}/CMinpack/enorm_.c
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
  )

  foreach(source_file_full_path ${3RD_CMINPACK_FMU_FILES})
    get_filename_component(source_file ${source_file_full_path} NAME)
    list(APPEND SOURCE_FMU_CMINPACK_FILES_LIST_QUOTED "\"external_solvers/${source_file}\"")
  endforeach()
  list(JOIN SOURCE_FMU_CMINPACK_FILES_LIST_QUOTED ",\n                                            " SOURCE_FMU_CMINPACK_FILES)
endif ()

######################################################################################################################
## Linear system files
set(SOURCE_FMU_LS_FILES_LIST simulation/solver/linearSolverLapack.c
                             simulation/solver/linearSolverTotalPivot.c
                             simulation/solver/linearSystem.c)

foreach(source_file ${SOURCE_FMU_LS_FILES_LIST})
  list(APPEND SOURCE_FMU_LS_FILES_LIST_QUOTED "\"${source_file}\"")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR})
endforeach()
list(JOIN SOURCE_FMU_LS_FILES_LIST_QUOTED ",\n                                                     " SOURCE_FMU_LS_FILES)


######################################################################################################################
## Mixed system files
set(SOURCE_FMU_MIXED_FILES_LIST simulation/solver/mixedSystem.c
                                simulation/solver/mixedSearchSolver.c)

foreach(source_file ${SOURCE_FMU_MIXED_FILES_LIST})
  list(APPEND SOURCE_FMU_MIXED_FILES_LIST_QUOTED "\"${source_file}\"")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR})
endforeach()
list(JOIN SOURCE_FMU_MIXED_FILES_LIST_QUOTED ",\n                                                    " SOURCE_FMU_MIXED_FILES)


######################################################################################################################
## CVODE files
set(SOURCE_FMU_CVODE_RUNTIME_FILES_LIST simulation/solver/cvode_solver.c
                                        simulation/solver/sundials_error.c
                                        simulation/solver/sundials_util.c)

foreach(source_file ${SOURCE_FMU_CVODE_RUNTIME_FILES_LIST})
  list(APPEND SOURCE_FMU_CVODE_RUNTIME_FILES_LIST_QUOTED "\"${source_file}\"")
  get_filename_component(DEST_DIR ${source_file} DIRECTORY)
  install(FILES ${source_file}
          DESTINATION ${SOURCE_FMU_SOURCES_DIR}/${DEST_DIR})
endforeach()
list(JOIN SOURCE_FMU_CVODE_RUNTIME_FILES_LIST_QUOTED ",\n                                                  " SOURCE_FMU_CVODE_RUNTIME_FILES)

# CVODE and KLU for the FMU. The public headers go to include/, the FMU's sources/
# directory; the sources and private headers flat to src/, its cvode_sources/. Every
# #include then resolves with sources/ as the only include directory and no
# definitions, as an importer building from <SourceFiles> compiles them.
set(SOURCE_FMU_CVODE_DIR ${SOURCE_FMU_SOURCES_DIR}/cvode_sources)
set(3RD_SUNDIALS_DIR ${OMCompiler_3rdParty_SOURCE_DIR}/sundials)
set(3RD_SUITESPARSE_DIR ${OMCompiler_3rdParty_SOURCE_DIR}/SuiteSparse)

set(3RD_SUNDIALS_FMU_DIRS cvode
                          sundials
                          sunmemory/system
                          nvector/serial
                          sunmatrix/band
                          sunmatrix/dense
                          sunmatrix/sparse
                          sunlinsol/dense
                          sunlinsol/klu
                          sunnonlinsol/fixedpoint
                          sunnonlinsol/newton)
set(3RD_SUNDIALS_FMU_FILES cvode/cvode.c
                           cvode/cvode_cli.c
                           cvode/cvode_io.c
                           cvode/cvode_ls.c
                           cvode/cvode_nls.c
                           cvode/cvode_proj.c
                           cvode/cvode_resize.c
                           sundials/sundatanode/sundatanode_inmem.c
                           sundials/sundials_adaptcontroller.c
                           sundials/sundials_adjointcheckpointscheme.c
                           sundials/sundials_adjointstepper.c
                           sundials/sundials_band.c
                           sundials/sundials_cli.c
                           sundials/sundials_context.c
                           sundials/sundials_datanode.c
                           sundials/sundials_dense.c
                           sundials/sundials_direct.c
                           sundials/sundials_domeigestimator.c
                           sundials/sundials_errors.c
                           sundials/sundials_futils.c
                           sundials/sundials_hashmap.c
                           sundials/sundials_iterative.c
                           sundials/sundials_linearsolver.c
                           sundials/sundials_logger.c
                           sundials/sundials_math.c
                           sundials/sundials_matrix.c
                           sundials/sundials_memory.c
                           sundials/sundials_nonlinearsolver.c
                           sundials/sundials_nvector.c
                           sundials/sundials_nvector_senswrapper.c
                           sundials/sundials_profiler.c
                           sundials/sundials_stepper.c
                           sundials/sundials_version.c
                           sunmemory/system/sundials_system_memory.c
                           nvector/serial/nvector_serial.c
                           sunmatrix/band/sunmatrix_band.c
                           sunmatrix/dense/sunmatrix_dense.c
                           sunmatrix/sparse/sunmatrix_sparse.c
                           sunlinsol/dense/sunlinsol_dense.c
                           sunlinsol/klu/sunlinsol_klu.c
                           sunnonlinsol/fixedpoint/sunnonlinsol_fixedpoint.c
                           sunnonlinsol/newton/sunnonlinsol_newton.c)

foreach(source_dir ${3RD_SUNDIALS_FMU_DIRS})
  file(GLOB private_headers ${3RD_SUNDIALS_DIR}/src/${source_dir}/*.h)
  install(FILES ${private_headers} DESTINATION ${SOURCE_FMU_CVODE_DIR}/src)
endforeach()
# Its quoted includes are relative to src/sundials, now its parent.
file(READ ${3RD_SUNDIALS_DIR}/src/sundials/sundatanode/sundatanode_inmem.h SUNDATANODE_INMEM_H)
string(REPLACE "#include \"" "#include \"../" SUNDATANODE_INMEM_H "${SUNDATANODE_INMEM_H}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/fmu_sundials/sundatanode/sundatanode_inmem.h "${SUNDATANODE_INMEM_H}")
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/fmu_sundials/sundatanode/sundatanode_inmem.h
        DESTINATION ${SOURCE_FMU_CVODE_DIR}/src/sundatanode)
install(FILES ${3RD_SUNDIALS_DIR}/src/sundials/stl/sunstl_vector.h
        DESTINATION ${SOURCE_FMU_CVODE_DIR}/src/stl)
foreach(source_file ${3RD_SUNDIALS_FMU_FILES})
  install(FILES ${3RD_SUNDIALS_DIR}/src/${source_file} DESTINATION ${SOURCE_FMU_CVODE_DIR}/src)
  get_filename_component(source_file_name ${source_file} NAME)
  list(APPEND SOURCE_FMU_CVODE_FILES_LIST_QUOTED "\"cvode_sources/${source_file_name}\"")
endforeach()

foreach(include_dir cvode nvector sundials sunlinsol sunmatrix sunmemory sunnonlinsol)
  install(DIRECTORY ${3RD_SUNDIALS_DIR}/include/${include_dir}
          DESTINATION ${SOURCE_FMU_CVODE_DIR}/include
          FILES_MATCHING PATTERN "*.h")
endforeach()

# The generated configuration describes the compiler OpenModelica was built with;
# leave out what another one might not support.
file(READ ${SUNDIALS_BINARY_DIR}/include/sundials/sundials_config.h SUNDIALS_FMU_CONFIG)
string(REGEX REPLACE "#define SUNDIALS_C_COMPILER_HAS_[A-Z_]+\n" "" SUNDIALS_FMU_CONFIG "${SUNDIALS_FMU_CONFIG}")
string(REPLACE "#define SUNDIALS_HAVE_POSIX_TIMERS\n" "" SUNDIALS_FMU_CONFIG "${SUNDIALS_FMU_CONFIG}")
string(REPLACE "#include \"sundials/sundials_export.h\""
               "#ifndef SUNDIALS_STATIC_DEFINE\n#define SUNDIALS_STATIC_DEFINE\n#endif\n#include \"sundials/sundials_export.h\""
               SUNDIALS_FMU_CONFIG "${SUNDIALS_FMU_CONFIG}")
string(REPLACE "#endif /* _SUNDIALS_CONFIG_H */"
               "#if !defined(_WIN32)\n#define SUNDIALS_HAVE_POSIX_TIMERS\n#endif\n\n#endif /* _SUNDIALS_CONFIG_H */"
               SUNDIALS_FMU_CONFIG "${SUNDIALS_FMU_CONFIG}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/fmu_sundials/sundials_config.h "${SUNDIALS_FMU_CONFIG}")
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/fmu_sundials/sundials_config.h
              ${SUNDIALS_BINARY_DIR}/include/sundials/sundials_export.h
        DESTINATION ${SOURCE_FMU_CVODE_DIR}/include/sundials)

file(GLOB 3RD_KLU_FMU_FILES ${3RD_SUITESPARSE_DIR}/KLU/Source/klu*.c)
list(FILTER 3RD_KLU_FMU_FILES EXCLUDE REGEX "/klu_z[^/]*\\.c$")
file(GLOB 3RD_SUITESPARSE_FMU_FILES ${3RD_SUITESPARSE_DIR}/AMD/Source/*.c
                                    ${3RD_SUITESPARSE_DIR}/BTF/Source/*.c
                                    ${3RD_SUITESPARSE_DIR}/COLAMD/Source/*.c)
list(APPEND 3RD_SUITESPARSE_FMU_FILES ${3RD_KLU_FMU_FILES}
                                      ${3RD_SUITESPARSE_DIR}/SuiteSparse_config/SuiteSparse_config.c)
file(GLOB 3RD_SUITESPARSE_FMU_PRIVATE_HEADERS ${3RD_SUITESPARSE_DIR}/AMD/Include/*_internal.h
                                              ${3RD_SUITESPARSE_DIR}/BTF/Include/*_internal.h
                                              ${3RD_SUITESPARSE_DIR}/KLU/Include/*_internal.h
                                              ${3RD_SUITESPARSE_DIR}/KLU/Include/klu_version.h)
install(FILES ${3RD_SUITESPARSE_FMU_FILES} ${3RD_SUITESPARSE_FMU_PRIVATE_HEADERS}
        DESTINATION ${SOURCE_FMU_CVODE_DIR}/src)
list(SORT 3RD_SUITESPARSE_FMU_FILES)
foreach(source_file_full_path ${3RD_SUITESPARSE_FMU_FILES})
  get_filename_component(source_file ${source_file_full_path} NAME)
  list(APPEND SOURCE_FMU_CVODE_FILES_LIST_QUOTED "\"cvode_sources/${source_file}\"")
endforeach()
list(JOIN SOURCE_FMU_CVODE_FILES_LIST_QUOTED ",\n                                     " SOURCE_FMU_CVODE_FILES)

# SuiteSparse's timer needs clock_gettime, which MinGW has only in winpthreads.
file(READ ${3RD_SUITESPARSE_DIR}/SuiteSparse_config/SuiteSparse_config.h SUITESPARSE_FMU_CONFIG)
string(REPLACE "// determine which timer to use, if any"
               "#ifndef NTIMER\n#define NTIMER\n#endif\n\n// determine which timer to use, if any"
               SUITESPARSE_FMU_CONFIG "${SUITESPARSE_FMU_CONFIG}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/fmu_suitesparse/SuiteSparse_config.h "${SUITESPARSE_FMU_CONFIG}")
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/fmu_suitesparse/SuiteSparse_config.h
              ${3RD_SUITESPARSE_DIR}/AMD/Include/amd.h
              ${3RD_SUITESPARSE_DIR}/BTF/Include/btf.h
              ${3RD_SUITESPARSE_DIR}/COLAMD/Include/colamd.h
              ${3RD_SUITESPARSE_DIR}/KLU/Include/klu.h
        DESTINATION ${SOURCE_FMU_CVODE_DIR}/include)

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

install(TARGETS SimulationRuntimeFMI)


# ######################################################################################################################
# Library: OpenModelicaFMIRuntimeC

file(GLOB OMC_SIMRT_FMI_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/fmi/*.c)
file(GLOB OMC_SIMRT_FMI_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/fmi/*.h)

add_library(OpenModelicaFMIRuntimeC STATIC)
add_library(omc::simrt::fmiruntime ALIAS OpenModelicaFMIRuntimeC)

target_sources(OpenModelicaFMIRuntimeC PRIVATE ${OMC_SIMRT_FMI_SOURCES})

# target_link_libraries(OpenModelicaFMIRuntimeC_base PUBLIC omc::config)
target_link_libraries(OpenModelicaFMIRuntimeC PUBLIC omc::3rd::fmilib)

install(TARGETS OpenModelicaFMIRuntimeC)
