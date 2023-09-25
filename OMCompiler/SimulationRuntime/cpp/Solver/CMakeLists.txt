


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

install(TARGETS OMCppCVode)


#####################################################################################################
# OMCppDASSL
set(OMC_SIMRT_CPP_SOLVER_DASSL_SOURCES DASSL/DASSL.cpp
                                       DASSL/DASSLSettings.cpp
                                       DASSL/FactoryExport.cpp)

add_library(OMCppDASSL SHARED)
add_library(omc::simrt::cpp::solver::dassl ALIAS OMCppDASSL)

target_sources(OMCppDASSL PRIVATE ${OMC_SIMRT_CPP_SOLVER_DASSL_SOURCES})

target_link_libraries(OMCppDASSL PRIVATE omc::simrt::cpp::core::modelica)
target_link_libraries(OMCppDASSL PRIVATE omc::simrt::cpp::core::solver)
target_link_libraries(OMCppDASSL PRIVATE omc::3rd::cdaskr)

install(TARGETS OMCppDASSL)


#####################################################################################################
# OMCppDgesvSolver
set(OMC_SIMRT_CPP_SOLVER_DGESV_SOURCES Dgesv/DgesvSolver.cpp
                                       Dgesv/DgesvSolverSettings.cpp
                                       Dgesv/FactoryExport.cpp)

add_library(OMCppDgesvSolver SHARED)
add_library(omc::simrt::cpp::solver::dgesvsolver ALIAS OMCppDgesvSolver)

target_sources(OMCppDgesvSolver PRIVATE ${OMC_SIMRT_CPP_SOLVER_DGESV_SOURCES})

target_link_libraries(OMCppDgesvSolver PRIVATE omc::simrt::cpp::core::modelica)
target_link_libraries(OMCppDgesvSolver PRIVATE omc::simrt::cpp::core::solver)
target_link_libraries(OMCppDgesvSolver PRIVATE ${LAPACK_LIBRARIES})

install(TARGETS OMCppDgesvSolver)

# OMCppDgesvSolver_static
add_library(OMCppDgesvSolver_static STATIC)
add_library(omc::simrt::cpp::solver::dgesvsolver::static ALIAS OMCppDgesvSolver_static)

target_sources(OMCppDgesvSolver_static PRIVATE ${OMC_SIMRT_CPP_SOLVER_DGESV_SOURCES})

target_compile_definitions(OMCppDgesvSolver_static PRIVATE RUNTIME_STATIC_LINKING)

target_link_libraries(OMCppDgesvSolver_static PUBLIC omc::simrt::cpp::core::modelica)

install(TARGETS OMCppDgesvSolver_static)
##


#####################################################################################################
# OMCppIda
set(OMC_SIMRT_CPP_SOLVER_IDA_SOURCES IDA/IDA.cpp
                                     IDA/IDASettings.cpp
                                     IDA/FactoryExport.cpp)

add_library(OMCppIda SHARED)
add_library(omc::simrt::cpp::solver::ida ALIAS OMCppIda)

target_sources(OMCppIda PRIVATE ${OMC_SIMRT_CPP_SOLVER_IDA_SOURCES})

target_link_libraries(OMCppIda PRIVATE omc::simrt::cpp::core::modelica)
target_link_libraries(OMCppIda PRIVATE omc::simrt::cpp::core::solver)
target_link_libraries(OMCppIda PRIVATE omc::3rd::sundials::ida)

install(TARGETS OMCppIda)


#####################################################################################################
# OMCppKinsol
set(OMC_SIMRT_CPP_SOLVER_KINSOL_SOURCES Kinsol/Kinsol.cpp
                                        Kinsol/KinsolSettings.cpp
                                        Kinsol/FactoryExport.cpp)

add_library(OMCppKinsol SHARED)
add_library(omc::simrt::cpp::solver::kinsol ALIAS OMCppKinsol)

target_sources(OMCppKinsol PRIVATE ${OMC_SIMRT_CPP_SOLVER_KINSOL_SOURCES})

target_link_libraries(OMCppKinsol PRIVATE omc::simrt::cpp::core::modelica)
target_link_libraries(OMCppKinsol PRIVATE omc::simrt::cpp::core::solver)
target_link_libraries(OMCppKinsol PRIVATE omc::3rd::sundials::kinsol)
target_link_libraries(OMCppKinsol PRIVATE ${LAPACK_LIBRARIES})

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

install(TARGETS OMCppLinearSolver)


#####################################################################################################
# OMCppNewton
set(OMC_SIMRT_CPP_SOLVER_NEWTON_SOURCES Newton/Newton.cpp
                                       Newton/NewtonSettings.cpp
                                       Newton/FactoryExport.cpp)

add_library(OMCppNewton SHARED)
add_library(omc::simrt::cpp::solver::newton ALIAS OMCppNewton)

target_sources(OMCppNewton PRIVATE ${OMC_SIMRT_CPP_SOLVER_NEWTON_SOURCES})

target_link_libraries(OMCppNewton PRIVATE omc::simrt::cpp::core::modelica)
target_link_libraries(OMCppNewton PRIVATE omc::simrt::cpp::core::solver)
target_link_libraries(OMCppNewton PRIVATE ${LAPACK_LIBRARIES})

install(TARGETS OMCppNewton)

# OMCppNewton_static
add_library(OMCppNewton_static STATIC)
add_library(omc::simrt::cpp::solver::newton::static ALIAS OMCppNewton_static)

target_sources(OMCppNewton_static PRIVATE ${OMC_SIMRT_CPP_SOLVER_NEWTON_SOURCES})

target_compile_definitions(OMCppNewton_static PRIVATE RUNTIME_STATIC_LINKING)

target_link_libraries(OMCppNewton_static PUBLIC omc::simrt::cpp::core::modelica)

install(TARGETS OMCppNewton_static)
##
