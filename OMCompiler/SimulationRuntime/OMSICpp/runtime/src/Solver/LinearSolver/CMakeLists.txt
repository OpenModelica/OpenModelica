cmake_minimum_required(VERSION 3.5...4.3)

project(${LinearSolverName})
if(DGESV_FOUND)
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${LinearSolverName} LinearSolver.cpp LinearSolverSettings.cpp FactoryExport.cpp  ${DGESV_SRCS} )
  target_link_libraries(${LinearSolverName}  ${SolverName}   ${KLU_LIBRARIES} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${ModelicaName})
else()
  #use full lapack
  add_library(${LinearSolverName} LinearSolver.cpp LinearSolverSettings.cpp FactoryExport.cpp )
  target_link_libraries(${LinearSolverName}  ${SolverName}   ${KLU_LIBRARIES} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})
endif(DGESV_FOUND)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${LinearSolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${LinearSolverName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${LinearSolverName} runtime/include/Core/Modelica.h)
target_link_libraries(${LinearSolverName}  ${SolverName}   ${KLU_LIBRARIES} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})




install(TARGETS ${LinearSolverName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/LinearSolver/LinearSolver.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/LinearSolver/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/LinearSolver)
