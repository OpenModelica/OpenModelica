cmake_minimum_required(VERSION 3.5)

project(${HybrjName})

add_library(${HybrjName} Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${HybrjName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

add_precompiled_header(${HybrjName} Core/Modelica.h)
target_link_libraries(${HybrjName} ${Boost_LIBRARIES})
target_link_libraries(${HybrjName}  ${SolverName}  ${LAPACK_LIBRARIES} ${CMINPACK_LIBRARY}  ${ModelicaName})

message(STATUS ${CMINPACK_LIBRARY})

install (TARGETS ${HybrjName} DESTINATION ${LIBINSTALLEXT})
