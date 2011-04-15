cmake_minimum_required (VERSION 2.6)

project(SettingsFactory)
# add the solver default implementation library
add_library(SettingsFactory SHARED GlobalSettings.cpp Factory.cpp  )
target_link_libraries( SettingsFactory ${Boost_LIBRARIES})


install (TARGETS SettingsFactory DESTINATION bin)
install (FILES "../Interfaces/GlobalSettings.xml" 
  DESTINATION bin/config)


  
  
 
