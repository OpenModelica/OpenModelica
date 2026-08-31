cmake_minimum_required(VERSION 3.5...4.3)

project(${KinsolName})
if(DGESV_FOUND)
  include_directories (${DGESV_INCLUDE_DIR})
  add_library(${KinsolName} Kinsol.cpp KinsolSettings.cpp FactoryExport.cpp  ${DGESV_SRCS})
  target_link_libraries(${KinsolName}  ${SolverName}  ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES}  ${ModelicaName} )
else()
  #use full Lapack
  add_library(${KinsolName} Kinsol.cpp KinsolSettings.cpp FactoryExport.cpp)
  target_link_libraries(${KinsolName}  ${SolverName}  ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES}  ${ModelicaName} ${LAPACK_LIBRARIES})
endif(DGESV_FOUND)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${KinsolName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
  if(MSVC)
    install(FILES $<TARGET_PDB_FILE:${KinsolName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
  endif(MSVC)
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${KinsolName} Include/Core/Modelica.h)
target_link_libraries(${KinsolName}  ${SolverName}  ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES}  ${ModelicaName} )




install(TARGETS ${KinsolName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/Kinsol/Kinsol.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/Kinsol/KinsolSettings.h
  ${OMSICPP_SOURCE_DIR}/runtime/include/Solver/Kinsol/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/Kinsol)
