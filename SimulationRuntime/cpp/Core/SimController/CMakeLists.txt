cmake_minimum_required (VERSION 2.6)

project(${SimManagerName})
add_executable(${SimManagerName}  Configuration.cpp Main.cpp  )
target_link_libraries( ${SimManagerName} ${Boost_LIBRARIES} ${CMAKE_DL_LIBS} )


install (TARGETS ${SimManagerName} DESTINATION bin)

