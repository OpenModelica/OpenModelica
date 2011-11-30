cmake_minimum_required (VERSION 2.6)

project(Modelica)

add_library(Modelica SHARED ModelicaSystem.cpp )

target_link_libraries (Modelica  System ModelicaExternalC)


GET_TARGET_PROPERTY(libModelicaSystem Modelica LOCATION)
GET_FILENAME_COMPONENT(libModelicaSystemName ${libModelicaSystem} NAME)
set (BOOST_LIBS ${Boost_LIBRARIES})
set (BOOS_INCLUDE ${Boost_INCLUDE_DIRS})
set (MODELICA_SYSTEM_LIB ${libModelicaSystemName})
 configure_file (
  "${PROJECT_SOURCE_DIR}/ModelicaConfic.inc.in"
  "${PROJECT_BINARY_DIR}/ModelicaConfic.inc"
  )


install (TARGETS Modelica DESTINATION bin)
install (FILES 
				
				${PROJECT_BINARY_DIR}/ModelicaConfic.inc
				DESTINATION bin)
				
				
install (FILES HistoryImpl.h Modelica.h DESTINATION include/omc/cpp)
install (FILES Policies/TextfileWriter.h DESTINATION include/omc/cpp/policies)


  
  
 
