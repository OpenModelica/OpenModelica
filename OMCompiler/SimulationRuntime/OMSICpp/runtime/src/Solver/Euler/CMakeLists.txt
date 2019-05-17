cmake_minimum_required(VERSION 2.8.9)

project(${EulerName})

add_library(${EulerName} Euler.cpp EulerSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${EulerName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
else(NOT BUILD_SHARED_LIBS)
 install(FILES $<TARGET_PDB_FILE:${EulerName}> DESTINATION ${LIBINSTALLEXT} OPTIONAL)
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${EulerName} runtime/include/Core/Modelica.h )
target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})




install(TARGETS ${EulerName} DESTINATION ${LIBINSTALLEXT})

