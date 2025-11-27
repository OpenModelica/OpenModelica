CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${DgesvName})

IF(DGESV_FOUND)
  MESSAGE(STATUS "DGESV enabled")
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${DgesvName}_static STATIC ${DGESV_SRCS})
  install(TARGETS ${DgesvName}_static DESTINATION ${LIBINSTALLEXT})
  install(FILES ${DGESV_HEADERS} DESTINATION include/omc/cpp/Solver/Dgesv)
  if(MSVC)
    if(TARGET_TYPE STREQUAL "STATIC_LIBRARY")
      set(libDgesvExt ${CMAKE_STATIC_LIBRARY_SUFFIX})
    elseif(TARGET_TYPE STREQUAL "SHARED_LIBRARY")
      set(libDgesvExt ${CMAKE_SHARED_LIBRARY_SUFFIX})
    endif()
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
