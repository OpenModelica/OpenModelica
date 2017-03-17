cmake_minimum_required(VERSION 2.8.9)

project(${NewtonName})

add_library(${NewtonName} Newton.cpp NewtonSettings.cpp FactoryExport)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${NewtonName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
endif(NOT BUILD_SHARED_LIBS)

target_link_libraries(${NewtonName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES}  ${ModelicaName})
add_precompiled_header(${NewtonName} Include/Core/Modelica.h)

install(TARGETS ${NewtonName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/Newton.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/NewtonSettings.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/Newton)
