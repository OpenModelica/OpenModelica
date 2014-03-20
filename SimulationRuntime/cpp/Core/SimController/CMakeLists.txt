cmake_minimum_required (VERSION 2.6)

project(${SimControllerName})

IF(ANALYZATION_MODE)
	message(STATUS "Building SimController for analyzation")
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
	add_library(${SimControllerName} STATIC Configuration.cpp  FactoryExport.cpp Initialization.cpp SimController.cpp SimManager.cpp)
	target_link_libraries( ${SimControllerName} ${SystemName} ${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} )
ELSE(ANALYZATION_MODE)
	add_library(${SimControllerName} SHARED Configuration.cpp  FactoryExport.cpp Initialization.cpp SimController.cpp SimManager.cpp)
	target_link_libraries( ${SimControllerName} ${OMCFactoryName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} )
ENDIF(ANALYZATION_MODE)


install (TARGETS ${SimControllerName} DESTINATION lib/omc/${LIBINSTALLEXT})

install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimData.h
			   ${CMAKE_SOURCE_DIR}/Include/Core/SimController/ISimController.h
        
      DESTINATION include/omc/cpp/Core/SimController)