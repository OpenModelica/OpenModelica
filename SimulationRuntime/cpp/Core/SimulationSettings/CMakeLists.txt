cmake_minimum_required (VERSION 2.6)

project(${SimulationSettings})
# add the solver default implementation library
IF(ANALYZATION_MODE)
	include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
	add_library(${SimulationSettings} STATIC GlobalSettings.cpp Factory.cpp FactoryExport.cpp )
ELSE(ANALYZATION_MODE)
	add_library(${SimulationSettings} SHARED GlobalSettings.cpp Factory.cpp FactoryExport.cpp )
ENDIF(ANALYZATION_MODE)
target_link_libraries( ${SimulationSettings} ${OMCFactoryName} ${Boost_LIBRARIES})


install (TARGETS ${SimulationSettings} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES "config/GlobalSettings.xml"
  DESTINATION share/omc/runtime/cpp/config)
install (FILES ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/IGlobalSettings.h
			   ${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/ISettingsFactory.h
  DESTINATION include/omc/cpp/Core/SimulationSettings)




