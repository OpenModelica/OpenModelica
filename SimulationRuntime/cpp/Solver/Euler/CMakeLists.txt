cmake_minimum_required(VERSION 2.8.9)

project(${EulerName})

add_library(${EulerName}_static STATIC Euler.cpp EulerSettings.cpp FactoryExport.cpp )
add_precompiled_header(${EulerName}_static Include/Core/Modelica.h )
set_target_properties(${EulerName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

add_library(${EulerName} SHARED Euler.cpp EulerSettings.cpp FactoryExport.cpp )
add_precompiled_header(${EulerName} Include/Core/Modelica.h )

target_link_libraries (${EulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )

install (TARGETS ${EulerName} ${EulerName}_static DESTINATION ${LIBINSTALLEXT})
install (FILES "config/EulerSettings.xml" DESTINATION share/omc/runtime/cpp/config)
