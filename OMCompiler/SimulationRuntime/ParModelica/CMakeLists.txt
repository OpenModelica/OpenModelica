
set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/ParModelica)

find_package(Boost COMPONENTS graph chrono)

if(Boost_graph_FOUND AND Boost_chrono_FOUND)
  omc_add_subdirectory(auto)
else()
  message(STATUS "Required boost libraries (graph, chrono) not found for ParModAuto. Disabling ParModAuto.")
endif()
