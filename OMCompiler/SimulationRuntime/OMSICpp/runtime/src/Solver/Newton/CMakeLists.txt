cmake_minimum_required(VERSION 3.5...4.3)

project(${NewtonName})
if(DGESV_FOUND)
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
else()
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
endif(DGESV_FOUND)
if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${NewtonName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${NewtonName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
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
  ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/Newton/Newton.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/Newton/NewtonSettings.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/CVode/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/Newton)
