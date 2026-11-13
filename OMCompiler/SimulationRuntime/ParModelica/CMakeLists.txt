cmake_minimum_required(VERSION 3.10)

project(OpenModelicaSimulationRuntimeParModelica LANGUAGES CXX)

omc_add_subdirectory(auto)

install(FILES explicit/openclrt/ParModelicaBuiltin.mo
        DESTINATION lib/omc)

find_package(OpenCL)

if(OpenCL_FOUND)
  omc_add_subdirectory(explicit/openclrt)
else()
  message(STATUS "Required OpenCL libraries not found for ParModExp. Disabling ParModExp.")
endif()
