cmake_minimum_required(VERSION 3.14)
project(omopcua)

# Loaded with dlopen("libomopcua" DLL_EXT) by embedded_server.c.
add_library(omopcua SHARED)
target_sources(omopcua PRIVATE omc_opc_ua.c)
set_target_properties(omopcua PROPERTIES PREFIX "lib")

target_link_libraries(omopcua PRIVATE omc::3rd::opcua omc::simrt::simruntime)
if(WIN32)
  target_link_libraries(omopcua PRIVATE ws2_32)
endif()

install(TARGETS omopcua)

if(OM_ENABLE_TESTSUITE)
  add_subdirectory(
    ${CMAKE_SOURCE_DIR}/testsuite/CTest/SimulationRuntime/opc/ua
    ${CMAKE_BINARY_DIR}/testsuite/CTest/SimulationRuntime/opc/ua
    EXCLUDE_FROM_ALL
  )
endif()
