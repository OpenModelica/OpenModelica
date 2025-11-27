CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${NewtonName})
IF(DGESV_FOUND)
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${NewtonName}
    Newton.cpp
    NewtonSettings.cpp
    FactoryExport.cpp
    ${DGESV_SRCS})
  target_link_libraries(${NewtonName}
    ${SolverName}
    ${ExtensionUtilitiesName}
    ${Boost_LIBRARIES}
    ${ModelicaName})
ELSE()
  add_library(${NewtonName}
    Newton.cpp
    NewtonSettings.cpp
    FactoryExport.cpp)
  target_link_libraries(${NewtonName}
    ${SolverName}
    ${ExtensionUtilitiesName}
    ${Boost_LIBRARIES}
    ${LAPACK_LIBRARIES}
    ${ModelicaName})
ENDIF(DGESV_FOUND)
if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${NewtonName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
  install(FILES $<TARGET_PDB_FILE:${NewtonName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)


target_link_libraries(${NewtonName}
  ${SolverName}
  ${ExtensionUtilitiesName}
  ${Boost_LIBRARIES}
  ${LAPACK_LIBRARIES}
  ${ModelicaName})
add_precompiled_header(${NewtonName} runtime/include/Core/Modelica.h)

install(TARGETS ${NewtonName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Newton/Newton.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/Newton/NewtonSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/CVode/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/Newton)
