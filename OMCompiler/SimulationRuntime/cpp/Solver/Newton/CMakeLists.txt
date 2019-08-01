cmake_minimum_required(VERSION 2.8.9)

project(${NewtonName})
IF(DGESV_FOUND)
 include_directories (${DGESV_INCLUDE_DIR})
 add_library(${NewtonName} Newton.cpp NewtonSettings.cpp FactoryExport ${DGESV_SRCS})
 target_link_libraries(${NewtonName}  ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${ModelicaName})
ELSE()
 add_library(${NewtonName} Newton.cpp NewtonSettings.cpp FactoryExport)
 target_link_libraries(${NewtonName}  ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})
ENDIF(DGESV_FOUND)
if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${NewtonName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)


add_precompiled_header(${NewtonName} Include/Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${NewtonName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${NewtonName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/Newton.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/NewtonSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/Newton)
