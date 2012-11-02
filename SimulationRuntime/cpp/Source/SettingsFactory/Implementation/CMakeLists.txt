cmake_minimum_required (VERSION 2.6)

project(${SettingsFactoryName})
# add the solver default implementation library
add_library(${SettingsFactoryName} SHARED GlobalSettings.cpp Factory.cpp  )
target_link_libraries( ${SettingsFactoryName} ${Boost_LIBRARIES})


install (TARGETS ${SettingsFactoryName} DESTINATION lib/omc/${LIBINSTALLEXT})
install (FILES "../Interfaces/GlobalSettings.xml" 
  DESTINATION share/omc/runtime/cpp/config)
install (FILES "../Interfaces/IGlobalSettings.h" 
  DESTINATION include/omc/cpp/SettingsFactory/Interfaces)

  
  
 
