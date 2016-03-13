cmake_minimum_required(VERSION 2.8.9)

project(${RTEulerName})

add_library(${RTEulerName}_static STATIC RTEuler.cpp RTEulerSettings.cpp FactoryExport.cpp )
set_target_properties(${RTEulerName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

add_library(${RTEulerName} SHARED RTEuler.cpp RTEulerSettings.cpp FactoryExport.cpp )

target_link_libraries (${RTEulerName} ${SolverName} ${Boost_LIBRARIES} ${LAPACK_LIBRARIES} )

install (TARGETS ${RTEulerName} ${RTEulerName}_static DESTINATION ${LIBINSTALLEXT})
