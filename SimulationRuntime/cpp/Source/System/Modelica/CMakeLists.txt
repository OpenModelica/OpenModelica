cmake_minimum_required (VERSION 2.6)

project(Modelica)

add_library(Modelica SHARED ModelicaSystem.cpp )

target_link_libraries (Modelica  System)

install (TARGETS Modelica DESTINATION bin)
install (FILES 
				build/CMakeLists.txt 
				#Modelica system default files 
				ModelicaSystem.cpp 
				ModelicaSystem.h
				DESTINATION bin)
install (FILES HistoryImpl.h Modelica.h DESTINATION include)
install (FILES Policies/TextfileWriter.h DESTINATION include/policies)


  
  
 
