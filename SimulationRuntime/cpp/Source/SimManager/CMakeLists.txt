cmake_minimum_required (VERSION 2.6)

project(SimManager)
add_executable(Simulation  Configuration.cpp Main.cpp  )
target_link_libraries( Simulation ${Boost_LIBRARIES})


install (TARGETS Simulation DESTINATION bin)
 
