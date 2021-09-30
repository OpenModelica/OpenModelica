

#####################################################################################################
# OMCppModelica
set(OMC_SIMRT_CPP_CORE_MODELICA_SOURCES Modelica/Modelica.cpp)

add_library(OMCppModelica SHARED)
add_library(omc::simrt::cpp::core::modelica ALIAS OMCppModelica)

target_sources(OMCppModelica PRIVATE ${OMC_SIMRT_CPP_CORE_MODELICA_SOURCES})

target_link_libraries(OMCppModelica PUBLIC omc::simrt::cpp::config)

target_link_options(OMCppModelica PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppModelica)


#####################################################################################################
# OMCppMath
set(OMC_SIMRT_CPP_CORE_MATH_SOURCES Math/ArrayOperations.cpp
                                    Math/Functions.cpp
                                    Math/FactoryExport.cpp)

add_library(OMCppMath SHARED)
add_library(omc::simrt::cpp::core::math ALIAS OMCppMath)

target_sources(OMCppMath PRIVATE ${OMC_SIMRT_CPP_CORE_MATH_SOURCES})

target_link_libraries(OMCppMath PUBLIC omc::simrt::cpp::config)

target_link_options(OMCppMath PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppMath)


#####################################################################################################
# OMCppSolver
set(OMC_SIMRT_CPP_CORE_SOLVER_SOURCES Solver/SolverDefaultImplementation.cpp
                                      Solver/AlgLoopSolverDefaultImplementation.cpp
                                      Solver/SolverSettings.cpp
                                      Solver/SystemStateSelection.cpp
                                      Solver/FactoryExport.cpp
                                      Solver/SimulationMonitor.cpp)

add_library(OMCppSolver SHARED)
add_library(omc::simrt::cpp::core::solver ALIAS OMCppSolver)

target_sources(OMCppSolver PRIVATE ${OMC_SIMRT_CPP_CORE_SOLVER_SOURCES})

target_link_libraries(OMCppSolver PUBLIC omc::simrt::cpp::config)
target_link_libraries(OMCppSolver PUBLIC omc::simrt::cpp::core::math)

target_link_options(OMCppSolver PRIVATE  -Wl,--no-undefined)

install(TARGETS OMCppSolver)
