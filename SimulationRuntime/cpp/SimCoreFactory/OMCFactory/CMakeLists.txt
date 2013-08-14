cmake_minimum_required (VERSION 2.6)

project(${OMCFactoryName})
# add the system default implementation library
add_library(${OMCFactoryName} STATIC OMCFactory.cpp)
target_link_libraries( ${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS})
if (UNIX)
set_target_properties(${OMCFactoryName} PROPERTIES COMPILE_FLAGS -fPIC)
endif(UNIX)

install (TARGETS ${OMCFactoryName} DESTINATION lib/omc/${LIBINSTALLEXT})

install (FILES
	    ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/FactoryConfig.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/FactoryPolicy.h
           ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/NonLinSolverOMCFactory.h
		${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SystemOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SolverSettingsOMCFactory.h
  DESTINATION include/omc/cpp/SimCoreFactory/Policies)



install (FILES
	    ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/OMCFactory/OMCFactory.h
DESTINATION include/omc/cpp/SimCoreFactory//OMCFactory/)


