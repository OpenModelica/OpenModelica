cmake_minimum_required(VERSION 2.8.9)

project(${NewtonName})

add_library(${NewtonName}_static STATIC Newton.cpp NewtonSettings.cpp FactoryExport )
add_precompiled_header(${NewtonName}_static Include/Core/Modelica.h )
set_target_properties(${NewtonName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")

add_library(${NewtonName} SHARED Newton.cpp NewtonSettings.cpp FactoryExport )
target_link_libraries( ${NewtonName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
add_precompiled_header(${NewtonName} Include/Core/Modelica.h )

install (TARGETS ${NewtonName} ${NewtonName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/Newton.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/NewtonSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
DESTINATION include/omc/cpp/Solver/Newton)
