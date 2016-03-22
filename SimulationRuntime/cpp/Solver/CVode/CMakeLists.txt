cmake_minimum_required(VERSION 2.8.9)

project(${CVodeName})
#include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

add_library(${CVodeName} CVode.cpp CVodeSettings.cpp FactoryExport.cpp)

if(NOT BUILD_SHARED_LIBS)
  set_target_properties(${CVodeName} PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
endif(NOT BUILD_SHARED_LIBS)

message(STATUS "Sundials Libraries used for linking:")
message(STATUS "${SUNDIALS_LIBRARIES}")

target_link_libraries(${CVodeName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES})
add_precompiled_header(${CVodeName} Include/Core/Modelica.h)

install(TARGETS ${CVodeName} DESTINATION ${LIBINSTALLEXT})
install(FILES
  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/CVode.h
  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
  DESTINATION include/omc/cpp/Solver/CVode)
