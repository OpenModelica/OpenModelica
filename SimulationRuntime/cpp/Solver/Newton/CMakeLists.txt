cmake_minimum_required (VERSION 2.8.6)

project(${NewtonName})

# add the solver default implementation library

include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
add_library(${NewtonName}_static STATIC Newton.cpp NewtonSettings.cpp FactoryExport )
add_precompiled_header(${NewtonName}_static Include/Core/Modelica.h )

add_library(${NewtonName} SHARED Newton.cpp NewtonSettings.cpp FactoryExport )
target_link_libraries( ${NewtonName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES})
add_precompiled_header(${NewtonName} Include/Core/Modelica.h )

install (TARGETS ${NewtonName} ${NewtonName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/Newton.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Newton/NewtonSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
DESTINATION include/omc/cpp/Solver/Newton)
