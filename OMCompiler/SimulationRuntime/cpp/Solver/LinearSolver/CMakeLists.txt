cmake_minimum_required(VERSION 2.8.9)

project(${LinearSolverName})
IF(DGESV_FOUND)
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${LinearSolverName} LinearSolver.cpp LinearSolverSettings.cpp FactoryExport.cpp  ${DGESV_SRCS} )
  target_link_libraries(${LinearSolverName}  ${SolverName}   ${KLU_LIBRARIES} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${ModelicaName})
ELSE()
 #use full lapack
 add_library(${LinearSolverName} LinearSolver.cpp LinearSolverSettings.cpp FactoryExport.cpp )
 target_link_libraries(${LinearSolverName}  ${SolverName}   ${KLU_LIBRARIES} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})
ENDIF(DGESV_FOUND)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${LinearSolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${LinearSolverName} Include/Core/Modelica.h)


install(FILES $<TARGET_PDB_FILE:${LinearSolverName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${LinearSolverName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/LinearSolver/LinearSolver.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/LinearSolver/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/LinearSolver)
