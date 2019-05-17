cmake_minimum_required (VERSION 2.8.9)

project(${ARKodeName})

add_library(${ARKodeName} ARKode.cpp ARKodeSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${ARKodeName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
  install(FILES $<TARGET_PDB_FILE:${ARKodeName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${ARKodeName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES})
add_precompiled_header(${ARKodeName} runtime/include/Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${ARKodeName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${ARKodeName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/ARKode/ARKode.h
  ${CMAKE_SOURCE_DIR}/runtime/include/Solver/ARKode/FactoryExport.h
  DESTINATION include/omc/omsicpp/Solver/ARKode)
