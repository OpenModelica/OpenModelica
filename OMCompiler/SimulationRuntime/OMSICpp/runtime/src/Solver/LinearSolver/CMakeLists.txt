CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

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
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
  install(FILES $<TARGET_PDB_FILE:${LinearSolverName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${LinearSolverName} runtime/include/Core/Modelica.h)
target_link_libraries(${LinearSolverName}  ${SolverName}   ${KLU_LIBRARIES} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})




install(TARGETS ${LinearSolverName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/LinearSolver/LinearSolver.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/LinearSolver/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/LinearSolver)
