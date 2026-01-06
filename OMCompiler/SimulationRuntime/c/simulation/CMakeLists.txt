cmake_minimum_required(VERSION 3.14)

find_package(LAPACK REQUIRED)

set(OMC_SIMRT_SIMULATION_SOURCES
  "arrayIndex.c"
  "jacobian_util.c"
  "modelinfo.c"
  "omc_simulation_util.c"
  "options.c"
  "results/MatVer4.cpp"
  "results/simulation_result_csv.cpp"
  "results/simulation_result_ia.cpp"
  "results/simulation_result_mat4.cpp"
  "results/simulation_result_plt.cpp"
  "results/simulation_result_wall.cpp"
  "results/simulation_result.cpp"
  "simulation_info_json.c"
  "simulation_input_xml.c"
  "simulation_omc_assert.c"
  "simulation_runtime.cpp"
  "socket.cpp"
  "solver/cvode_solver.c"
  "solver/dae_mode.c"
  "solver/dassl.c"
  "solver/delay.c"
  "solver/embedded_server.c"
  "solver/events.c"
  "solver/external_input.c"
  "solver/fmi_events.c"
  "solver/gbode_conf.c"
  "solver/gbode_ctrl.c"
  "solver/gbode_events.c"
  "solver/gbode_main.c"
  "solver/gbode_nls.c"
  "solver/gbode_internal_nls.c"
  "solver/gbode_sparse.c"
  "solver/gbode_step.c"
  "solver/gbode_tableau.c"
  "solver/gbode_util.c"
  "solver/ida_solver.c"
  "solver/initialization/initialization.c"
  "solver/jacobian_analysis.c"
  "solver/jacobianSymbolical.c"
  "solver/kinsol_b.c"
  "solver/kinsolSolver.c"
  "solver/linearSolverKlu.c"
  "solver/linearSolverLapack.c"
  "solver/linearSolverLis.c"
  "solver/linearSolverTotalPivot.c"
  "solver/linearSolverUmfpack.c"
  "solver/linearSystem.c"
  "solver/mixedSearchSolver.c"
  "solver/mixedSystem.c"
  "solver/model_help.c"
  "solver/newton_diagnostics.c"
  "solver/newtonIteration.c"
  "solver/nonlinearSolverHomotopy.c"
  "solver/nonlinearSolverHybrd.c"
  "solver/nonlinearSolverNewton.c"
  "solver/nonlinearSystem.c"
  "solver/nonlinearValuesList.c"
  "solver/omc_math.c"
  "solver/perform_qss_simulation.c"
  "solver/perform_simulation.c"
  "solver/real_time_sync.c"
  "solver/solver_main.c"
  "solver/spatialDistribution.c"
  "solver/stateset.c"
  "solver/sundials_error.c"
  "solver/sundials_util.c"
  "solver/sym_solver_ssc.c"
  "solver/synchronous.c"
)

set(OMC_SIMRT_SIMULATION_HEADERS
  "arrayIndex.h"
  "jacobian_util.h"
  "modelinfo.h"
  "omc_simulation_util.h"
  "options.h"
  "results/MatVer4.h"
  "results/simulation_result_csv.h"
  "results/simulation_result_ia.h"
  "results/simulation_result_mat4.h"
  "results/simulation_result_plt.h"
  "results/simulation_result_wall.h"
  "results/simulation_result.h"
  "simulation_info_json.h"
  "simulation_input_xml.h"
  "simulation_omc_assert.h"
  "simulation_runtime.h"
  "socket.h"
  "solver/cvode_solver.h"
  "solver/dae_mode.h"
  "solver/dassl.h"
  "solver/delay.h"
  "solver/embedded_server.h"
  "solver/epsilon.h"
  "solver/events.h"
  "solver/external_input.h"
  "solver/fmi_events.h"
  "solver/gbode_conf.h"
  "solver/gbode_ctrl.h"
  "solver/gbode_events.h"
  "solver/gbode_main.h"
  "solver/gbode_nls.h"
  "solver/gbode_sparse.h"
  "solver/gbode_step.h"
  "solver/gbode_tableau.h"
  "solver/gbode_util.h"
  "solver/ida_solver.h"
  "solver/initialization/initialization.h"
  "solver/jacobian_analysis.h"
  "solver/jacobianSymbolical.h"
  "solver/kinsol_b.h"
  "solver/kinsolSolver.h"
  "solver/linearSolverKlu.h"
  "solver/linearSolverLapack.h"
  "solver/linearSolverLis.h"
  "solver/linearSolverTotalPivot.h"
  "solver/linearSolverUmfpack.h"
  "solver/linearSystem.h"
  "solver/mixedSearchSolver.h"
  "solver/mixedSystem.h"
  "solver/model_help.h"
  "solver/newton_diagnostics.h"
  "solver/newtonIteration.h"
  "solver/nonlinearSolverHomotopy.h"
  "solver/nonlinearSolverHybrd.h"
  "solver/nonlinearSolverNewton.h"
  "solver/nonlinearSystem.h"
  "solver/nonlinearValuesList.h"
  "solver/omc_math.h"
  "solver/perform_qss_simulation.h"
  "solver/perform_simulation.h"
  "solver/real_time_sync.h"
  "solver/solver_main.h"
  "solver/spatialDistribution.h"
  "solver/stateset.h"
  "solver/sundials_error.h"
  "solver/sundials_util.h"
  "solver/sym_solver_ssc.h"
  "solver/synchronous.h"
)

add_library(OpenModelicaRuntimeCSimulation OBJECT ${OMC_SIMRT_SIMULATION_SOURCES})
add_library(omc::simrt::simruntime::simulation ALIAS OpenModelicaRuntimeCSimulation)

target_include_directories(OpenModelicaRuntimeCSimulation
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/results>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/solver>
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/solver/initialization>

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
