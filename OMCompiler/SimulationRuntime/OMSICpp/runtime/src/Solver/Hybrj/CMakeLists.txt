CMAKE_MINIMUM_REQUIRED(VERSION 3.5)

project(${HybrjName})

add_library(${HybrjName} Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${HybrjName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
IF(MSVC)
  install(FILES $<TARGET_PDB_FILE:${HybrjName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
ENDIF(MSVC)
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${HybrjName} runtime/include/Solver/Modelica.h)
target_link_libraries(${HybrjName} ${Boost_LIBRARIES})
target_link_libraries(${HybrjName}  ${SolverName}  ${LAPACK_LIBRARIES} ${CMINPACK_LIBRARY}  ${ModelicaName})

message(STATUS ${CMINPACK_LIBRARY})

install (TARGETS ${HybrjName} DESTINATION ${LIBINSTALLEXT})
