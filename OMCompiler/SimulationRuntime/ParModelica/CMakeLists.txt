
find_package(Boost COMPONENTS graph chrono)

if(Boost_graph_FOUND AND Boost_chrono_FOUND)
  omc_add_subdirectory(auto)
else()
  message(STATUS "Required boost libraries (graph, chrono) not found for ParModAuto. Disabling ParModAuto.")
endif()

find_package(OpenCL)

if(OpenCL_FOUND)
  omc_add_subdirectory(explicit/openclrt)
else()
  message(STATUS "Required OpenCL libraries not found for ParModExp. Disabling ParModExp.")
endif()
