cmake_minimum_required(VERSION 2.8.9)

project(${CVodeName})
#include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

add_library(${CVodeName}_static STATIC CVode.cpp CVodeSettings.cpp FactoryExport.cpp)
add_precompiled_header(${CVodeName}_static Include/Core/Modelica.h )
set_target_properties(${CVodeName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING;ENABLE_SUNDIALS_STATIC")
install (TARGETS ${CVodeName}_static DESTINATION ${LIBINSTALLEXT})

MESSAGE(STATUS "Sundials Libraries used for linking:")
MESSAGE(STATUS "${SUNDIALS_LIBRARIES}")
add_library(${CVodeName} SHARED CVode.cpp CVodeSettings.cpp FactoryExport.cpp  )
target_link_libraries (${CVodeName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES})
add_precompiled_header(${CVodeName} Include/Core/Modelica.h )

install (TARGETS ${CVodeName} ${CVodeName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/CVode.h
                ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
DESTINATION include/omc/cpp/Solver/CVode)
