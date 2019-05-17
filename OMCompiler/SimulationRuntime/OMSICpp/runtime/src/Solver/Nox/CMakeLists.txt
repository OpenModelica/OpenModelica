cmake_minimum_required(VERSION 2.8.9)

project(${NoxName})

add_library(${NoxName} Nox.cpp NoxSettings.cpp FactoryExport.cpp NoxLapackInterface.cpp NOX_StatusTest_SgnChange.C)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${NoxName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
else(NOT BUILD_SHARED_LIBS)
install(FILES $<TARGET_PDB_FILE:${NoxName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${NoxName} runtime/include/Core/Modelica.h)
target_link_libraries(${NoxName}  ${SolverName}  ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${TRILINOS_LIBRARIES} )    #C:/OpenModelica/OMCompiler/SimulationRuntime/cpp/Solver/KLU/OMCppklu_static.lib
#target_link_libraries(${NoxName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES} ${kluName})



install(TARGETS ${NoxName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/Include/Solver/Nox/Nox.h
  ${CMAKE_SOURCE_DIR}/runtime/Include/Solver/Nox/NoxSettings.h
  ${CMAKE_SOURCE_DIR}/runtime/Include/Solver/Nox/FactoryExport.h
  ${CMAKE_SOURCE_DIR}/runtime/Include/Solver/Nox/NoxLapackInterface.h
  ${CMAKE_SOURCE_DIR}/runtime/Include/Solver/Nox/NOX_StatusTest_SgnChange.H
  DESTINATION include/omc/omsicpp/Solver/Nox)
