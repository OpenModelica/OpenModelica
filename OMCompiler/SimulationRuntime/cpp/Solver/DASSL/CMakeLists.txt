cmake_minimum_required(VERSION 3.5)

project(${DASSLName})

include_directories (${CDASKR_INCLUDE_DIR})

add_library(${DASSLName} ${CDASKR_SRCS} DASSL.cpp DASSLSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${DASSLName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${DASSLName} ${SolverName} ${ExtensionUtilitiesName} ${ModelicaName})
add_precompiled_header(${DASSLName} Core/Modelica.h)

install(FILES $<TARGET_PDB_FILE:${DASSLName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)

install(TARGETS ${DASSLName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Solver/DASSL/DASSL.h
  ${CMAKE_SOURCE_DIR}/Solver/DASSL/DASSLSettings.h
  ${CMAKE_SOURCE_DIR}/Solver/DASSL/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/DASSL)
