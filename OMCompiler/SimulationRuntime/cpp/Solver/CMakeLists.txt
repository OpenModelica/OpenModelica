


#####################################################################################################
# OMCppCVode
set(OMC_SIMRT_CPP_SOLVER_CVODE_SOURCES CVode/CVode.cpp
                                       CVode/CVodeSettings.cpp
                                       CVode/FactoryExport.cpp)

add_library(OMCppCVode SHARED)
add_library(omc::simrt::cpp::solver::cvode ALIAS OMCppCVode)

target_sources(OMCppCVode PRIVATE ${OMC_SIMRT_CPP_SOLVER_CVODE_SOURCES})

target_link_libraries(OMCppCVode PRIVATE omc::simrt::cpp::core::modelica)
target_link_libraries(OMCppCVode PRIVATE omc::simrt::cpp::core::solver)
target_link_libraries(OMCppCVode PRIVATE omc::3rd::sundials::cvode)

target_link_options(OMCppCVode PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppCVode)


#####################################################################################################
# OMCppKinsol
set(OMC_SIMRT_CPP_SOLVER_KINSOL_SOURCES Kinsol/Kinsol.cpp
                                        Kinsol/KinsolLapack.cpp
                                        Kinsol/KinsolSettings.cpp
                                        Kinsol/FactoryExport.cpp)

add_library(OMCppKinsol SHARED)
add_library(omc::simrt::cpp::solver::kinsol ALIAS OMCppKinsol)

target_sources(OMCppKinsol PRIVATE ${OMC_SIMRT_CPP_SOLVER_KINSOL_SOURCES})

target_link_libraries(OMCppKinsol PRIVATE omc::simrt::cpp::core::modelica)
target_link_libraries(OMCppKinsol PRIVATE omc::simrt::cpp::core::solver)
target_link_libraries(OMCppKinsol PRIVATE omc::3rd::sundials::kinsol)
target_link_libraries(OMCppKinsol PRIVATE ${LAPACK_LIBRARIES})

target_link_options(OMCppKinsol PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppKinsol)


#####################################################################################################
# OMCppLinearSolver
set(OMC_SIMRT_CPP_SOLVER_LINEAR_SOLVER_SOURCES LinearSolver/LinearSolver.cpp
                                               LinearSolver/LinearSolverSettings.cpp
                                               LinearSolver/FactoryExport.cpp)

add_library(OMCppLinearSolver SHARED)
add_library(omc::simrt::cpp::solver::linsolver ALIAS OMCppLinearSolver)

target_sources(OMCppLinearSolver PRIVATE ${OMC_SIMRT_CPP_SOLVER_LINEAR_SOLVER_SOURCES})

target_link_libraries(OMCppLinearSolver PRIVATE omc::simrt::cpp::core::modelica)
target_link_libraries(OMCppLinearSolver PRIVATE omc::simrt::cpp::core::solver)
target_link_libraries(OMCppLinearSolver PRIVATE ${LAPACK_LIBRARIES})

target_link_options(OMCppLinearSolver PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppLinearSolver)