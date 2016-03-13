cmake_minimum_required(VERSION 2.8.9)

project(${BroydenName})

#include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
add_library(${BroydenName}_static STATIC Broyden.cpp BroydenSettings.cpp FactoryExport.cpp )
add_precompiled_header(${BroydenName}_static Include/Core/Modelica.h )
set_target_properties(${BroydenName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")

add_library(${BroydenName} SHARED Broyden.cpp BroydenSettings.cpp FactoryExport )
target_link_libraries( ${BroydenName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )#C:/OpenModelica/OMCompiler/SimulationRuntime/cpp/Solver/KLU/OMCppklu_static.lib)
#target_link_libraries(${BroydenName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} ${kluName})
add_precompiled_header(${BroydenName} Include/Core/Modelica.h )

install (TARGETS ${BroydenName} ${BroydenName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES    ${CMAKE_SOURCE_DIR}/Include/Solver/Broyden/Broyden.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Broyden/BroydenSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Broyden/FactoryExport.h
DESTINATION include/omc/cpp/Solver/Broyden)
