cmake_minimum_required(VERSION 2.8.9)

project(${IDAName})
#include_directories(${SUNDIALS_INCLUDE_DIR}/ida ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

add_library(${IDAName}_static STATIC IDA.cpp IDASettings.cpp FactoryExport.cpp)
set_target_properties(${IDAName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
add_precompiled_header(${IDAName}_static Include/Core/Modelica.h )

add_library(${IDAName} SHARED IDA.cpp IDASettings.cpp FactoryExport.cpp)
target_link_libraries (${IDAName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES})
add_precompiled_header(${IDAName} Include/Core/Modelica.h )

install (TARGETS ${IDAName} ${IDAName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/IDA/IDA.h
                ${CMAKE_SOURCE_DIR}/Include/Solver/IDA/FactoryExport.h
DESTINATION include/omc/cpp/Solver/IDA)
