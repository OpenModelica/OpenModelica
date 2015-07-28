cmake_minimum_required (VERSION 2.8.6)

project(${KinsolName})
include_directories(${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
# add the solver default implementation library

add_library(${KinsolName}_static STATIC Kinsol.cpp KinsolSettings.cpp FactoryExport.cpp)
include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
add_precompiled_header(${KinsolName}_static Include/Core/Modelica.h)
set_target_properties(${KinsolName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")

add_library(${KinsolName} SHARED Kinsol.cpp KinsolSettings.cpp FactoryExport.cpp)
add_precompiled_header(${KinsolName} Include/Core/Modelica.h )

if (UNIX)
	set_target_properties(${KinsolName}_static PROPERTIES COMPILE_FLAGS -fPIC)
	set_target_properties(${KinsolName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

target_link_libraries(${KinsolName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES} ${LAPACK_LIBRARIES})

install (TARGETS ${KinsolName} ${KinsolName}_static DESTINATION ${LIBINSTALLEXT})

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/Kinsol.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/KinsolSettings.h
                  ${CMAKE_SOURCE_DIR}/Include/Solver/Kinsol/FactoryExport.h
DESTINATION include/omc/cpp/Solver/Kinsol)








