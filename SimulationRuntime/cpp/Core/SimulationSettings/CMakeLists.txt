cmake_minimum_required (VERSION 2.6)

project(${SimulationSettings})
# add the solver default implementation library
add_library(${SimulationSettings} SHARED GlobalSettings.cpp Factory.cpp  )
target_link_libraries( ${SimulationSettings} ${Boost_LIBRARIES})


install (TARGETS ${SimulationSettings} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES "config/GlobalSettings.xml"
  DESTINATION share/omc/runtime/cpp/config)
install (FILES "${CMAKE_SOURCE_DIR}/Include/Core/SimulationSettings/IGlobalSettings.h"
  DESTINATION include/omc/cpp/Core/SimulationSettings)




