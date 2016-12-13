cmake_minimum_required(VERSION 2.8.9)

project(${LinearSolverName})

add_library(${LinearSolverName} LinearSolver.cpp LinearSolverSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${LinearSolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${LinearSolverName} Include/Core/Modelica.h)
target_link_libraries(${LinearSolverName}   ${KLU_LIBRARIES} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES})    #C:/OpenModelica/OMCompiler/SimulationRuntime/cpp/Solver/KLU/OMCppklu_static.lib
#target_link_libraries(${LinearSolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES} ${kluName})

install(TARGETS ${LinearSolverName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/LinearSolver/LinearSolver.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/LinearSolver/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/LinearSolver)
