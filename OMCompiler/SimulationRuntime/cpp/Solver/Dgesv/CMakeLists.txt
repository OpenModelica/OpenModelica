cmake_minimum_required(VERSION 2.8.9)

project(${DgesvName})

IF(DGESV_FOUND)
  MESSAGE(STATUS "DGESV enabled")
  MESSAGE(STATUS "AHeu: Target name ${DgesvName}")
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${DgesvName}_static STATIC ${DGESV_SRCS})
  install(TARGETS ${DgesvName}_static DESTINATION ${LIBINSTALLEXT})
  install(FILES ${DGESV_HEADERS} DESTINATION include/omc/cpp/Solver/Dgesv)
  if(MSVC)
    # TODO: This is not allowed: cmake --help-policy CMP0026
    GET_TARGET_PROPERTY(libDgesvLocation ${DgesvName}_static LOCATION)
    GET_FILENAME_COMPONENT(libDgesvExt ${libDgesvLocation} EXT CACHE)
  endif()

  add_library(${DgesvSolverName} DgesvSolver.cpp DgesvSolverSettings.cpp FactoryExport.cpp)

  if(NOT BUILD_SHARED_LIBS)
    set_target_properties(${DgesvSolverName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
  endif(NOT BUILD_SHARED_LIBS)

  target_link_libraries(${DgesvSolverName}  ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})
  add_precompiled_header(${DgesvSolverName} Core/Modelica.h)

  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${DgesvSolverName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif()

  install(TARGETS ${DgesvSolverName} DESTINATION ${LIBINSTALLEXT})
  install(FILES
    ${CMAKE_SOURCE_DIR}/Solver/Dgesv/DgesvSolver.h
    ${CMAKE_SOURCE_DIR}/Solver/Dgesv/DgesvSolverSettings.h
    ${CMAKE_SOURCE_DIR}/Solver/Dgesv/FactoryExport.h
    DESTINATION include/omc/cpp/Solver/Dgesv)

ELSE()
  MESSAGE(STATUS "DGESV disabled")
ENDIF(DGESV_FOUND)

