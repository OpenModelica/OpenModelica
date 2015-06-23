cmake_minimum_required (VERSION 2.8.6)

project(${CVodeName})
#include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})

# add the solver default implementation library

add_library(${CVodeName}_static STATIC CVode.cpp CVodeSettings.cpp FactoryExport.cpp)
add_precompiled_header(${CVodeName}_static Include/Core/Modelica.h )
set_target_properties(${CVodeName}_static PROPERTIES COMPILE_DEFINITIONS "RUNTIME_STATIC_LINKING")
install (TARGETS ${CVodeName}_static DESTINATION ${LIBINSTALLEXT})

add_library(${CVodeName} SHARED CVode.cpp CVodeSettings.cpp FactoryExport.cpp  )
target_link_libraries (${CVodeName} ${SolverName} ${ExtensionUtilitiesName} ${Boost_LIBRARIES} ${SUNDIALS_LIBRARIES})
add_precompiled_header(${CVodeName} Include/Core/Modelica.h )

install (TARGETS ${CVodeName} ${CVodeName}_static DESTINATION ${LIBINSTALLEXT})

if (UNIX)
	set_target_properties(${CVodeName}_static PROPERTIES COMPILE_FLAGS -fPIC)
	set_target_properties(${CVodeName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

#target_link_libraries( Euler ${Boost_serialization_LIBRARY})


#install (FILES "../Interfaces/EulerSettings.xml"
 # DESTINATION bin/config)

install (FILES  ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/CVode.h
                ${CMAKE_SOURCE_DIR}/Include/Solver/CVode/FactoryExport.h
DESTINATION include/omc/cpp/Solver/CVode)
