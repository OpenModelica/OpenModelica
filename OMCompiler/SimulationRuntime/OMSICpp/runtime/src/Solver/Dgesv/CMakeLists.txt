cmake_minimum_required(VERSION 2.8.9)

project(${DgesvName})

IF(DGESV_FOUND)
  MESSAGE(STATUS "DGESV enabled")
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${DgesvName}_static STATIC ${DGESV_SRCS})
  install(TARGETS ${DgesvName}_static DESTINATION ${LIBINSTALLEXT})
  install(FILES ${DGESV_HEADERS} DESTINATION include/omc/omsicpp/Solver/Dgesv)
  GET_TARGET_PROPERTY(libDgesvLocation ${DgesvName}_static LOCATION)
  GET_FILENAME_COMPONENT(libDgesvExt ${libDgesvLocation} EXT CACHE)

  add_library(${DgesvSolverName} STATIC DgesvSolver.cpp DgesvSolverSettings.cpp FactoryExport.cpp)

  set_target_properties(${DgesvSolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
  install(TARGETS ${DgesvSolverName} DESTINATION ${LIBINSTALLEXT})
  install(FILES
    ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Dgesv/DgesvSolver.h
    ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Dgesv/FactoryExport.h
    DESTINATION include/omc/omsicpp/Solver/Dgesv)

ELSE()
  MESSAGE(STATUS "DGESV disabled")
ENDIF(DGESV_FOUND)

