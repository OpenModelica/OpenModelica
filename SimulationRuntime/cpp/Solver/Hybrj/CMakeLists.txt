cmake_minimum_required (VERSION 2.8.6)

project(${HybrjName})
# add the solver default implementation library

add_library(${HybrjName}_static STATIC Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp )
set_target_properties(${HybrjName}_static PROPERTIES COMPILE_DEFINITIONS "DRUNTIME_STATIC_LINKING")
add_precompiled_header(${HybrjName}_static Include/Core/Modelica.h )
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

add_library(${HybrjName} SHARED Hybrj.cpp HybrjSettings.cpp FactoryExport.cpp )
add_precompiled_header(${HybrjName} Include/Core/Modelica.h )

target_link_libraries( ${HybrjName} ${Boost_LIBRARIES})
target_link_libraries( ${HybrjName} ${LAPACK_LIBRARIES} ${CMINPACK_LIBRARY})
message(STATUS ${CMINPACK_LIBRARY})

install (TARGETS ${HybrjName} ${HybrjName}_static DESTINATION ${LIBINSTALLEXT})