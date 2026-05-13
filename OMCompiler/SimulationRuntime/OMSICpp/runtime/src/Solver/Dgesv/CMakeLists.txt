cmake_minimum_required(VERSION 3.5)

project(${DgesvName})

if(DGESV_FOUND)
  message(STATUS "DGESV enabled")
  include_directories (${DGESV_INCLUDE_DIR})

  add_library(${DgesvName} STATIC ${DGESV_SRCS})
  install(TARGETS ${DgesvName} DESTINATION ${LIBINSTALLEXT})
  install(FILES ${DGESV_HEADERS} DESTINATION include/omc/omsicpp/Solver/Dgesv)

  add_library(${DgesvSolverName} STATIC DgesvSolver.cpp DgesvSolverSettings.cpp FactoryExport.cpp)

  set_target_properties(${DgesvSolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
  install(TARGETS ${DgesvSolverName} DESTINATION ${LIBINSTALLEXT})
  install(FILES
    ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/Dgesv/DgesvSolver.h
    ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/Dgesv/FactoryExport.h
    DESTINATION include/omc/omsicpp/Solver/Dgesv)

else()
  message(STATUS "DGESV disabled")
endif(DGESV_FOUND)
