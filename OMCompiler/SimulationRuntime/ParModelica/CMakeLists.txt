cmake_minimum_required(VERSION 3.10)

project(OpenModelicaSimulationRuntimeParModelica LANGUAGES CXX)

omc_add_subdirectory(auto)

find_package(OpenCL)

if(OpenCL_FOUND)
  omc_add_subdirectory(explicit/openclrt)
else()
  message(STATUS "Required OpenCL libraries not found for ParModExp. Disabling ParModExp.")
endif()
