cmake_minimum_required (VERSION 2.8.6)

project(${OMCFactoryName})

IF(RUNTIME_STATIC_LINKING)
	message(STATUS "Building OMCFactory in analyzation mode")
	# add the system default implementation library
	add_library(${OMCFactoryName}_static STATIC OMCFactory.cpp StaticOMCFactory.cpp)
	#LINK_DIRECTORIES(${CMAKE_SOURCE_DIR}/../../../../build/lib/omc/${LIBINSTALLEXT})
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR}/kinsol ${SUNDIALS_INCLUDE_DIR})
	install (TARGETS ${OMCFactoryName}_static DESTINATION lib/omc/${LIBINSTALLEXT})
	if (UNIX)
		set_target_properties(${OMCFactoryName}_static PROPERTIES COMPILE_FLAGS -fPIC)
	endif(UNIX)
    
ELSE(RUNTIME_STATIC_LINKING)
	# add the system default implementation library
	add_library(${OMCFactoryName} STATIC OMCFactory.cpp)
	target_link_libraries( ${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS})
	install (TARGETS ${OMCFactoryName} DESTINATION lib/omc/${LIBINSTALLEXT})
	if (UNIX)
		set_target_properties(${OMCFactoryName} PROPERTIES COMPILE_FLAGS -fPIC)
	endif(UNIX)
    add_precompiled_header(${OMCFactoryName} Include/Core/Modelica.h )
ENDIF(RUNTIME_STATIC_LINKING)

IF(RUNTIME_STATIC_LINKING)
  install (FILES
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/FactoryConfig.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/FactoryPolicy.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticLinSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticSystemOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h
  DESTINATION include/omc/cpp/SimCoreFactory/Policies)
  install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/OMCFactory/StaticOMCFactory.h DESTINATION include/omc/cpp/SimCoreFactory/OMCFactory/)
ENDIF(RUNTIME_STATIC_LINKING)

install (FILES
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/FactoryConfig.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/FactoryPolicy.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/LinSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/NonLinSolverOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SystemOMCFactory.h
        ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/Policies/SolverSettingsOMCFactory.h
DESTINATION include/omc/cpp/SimCoreFactory/Policies)

install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/OMCFactory/OMCFactory.h DESTINATION include/omc/cpp/SimCoreFactory/OMCFactory/)
install (FILES ${CMAKE_SOURCE_DIR}/Include/SimCoreFactory/ObjectFactory.h DESTINATION include/omc/cpp/SimCoreFactory)