cmake_minimum_required (VERSION 2.8.6)

project(${SimulationSettings})
# add the solver default implementation library
IF(RUNTIME_STATIC_LINKING)
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
	add_library(${SimulationSettings}_static STATIC GlobalSettings.cpp Factory.cpp FactoryExport.cpp)
	install (TARGETS ${SimulationSettings}_static DESTINATION lib/omc/${LIBINSTALLEXT})
ELSE(RUNTIME_STATIC_LINKING)
	add_library(${SimulationSettings} SHARED GlobalSettings.cpp Factory.cpp FactoryExport.cpp)
	target_link_libraries( ${SimulationSettings} ${OMCFactoryName} ${Boost_LIBRARIES})
	install (TARGETS ${SimulationSettings} DESTINATION lib/omc/${LIBINSTALLEXT})
ENDIF(RUNTIME_STATIC_LINKING)

install (FILES "config/GlobalSettings.xml"
  DESTINATION share/omc/runtime/cpp/config)
install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/IGlobalSettings.h
			   ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/ISettingsFactory.h
               ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/ISimControllerSettings.h
  DESTINATION include/omc/cpp/Core/SimulationSettings)

IF(RUNTIME_STATIC_LINKING)
  install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/Factory.h
  DESTINATION include/omc/cpp/Core/SimulationSettings)
ENDIF(RUNTIME_STATIC_LINKING)




