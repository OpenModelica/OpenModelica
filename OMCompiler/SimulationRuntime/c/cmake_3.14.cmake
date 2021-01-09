cmake_minimum_required(VERSION 3.14)

project(SimulationRuntimeC)

file(GLOB OMC_SIMRT_UTIL_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/util/*.c)
file(GLOB OMC_SIMRT_UTIL_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/util/*.h)

file(GLOB OMC_SIMRT_META_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/meta/*.c)
file(GLOB OMC_SIMRT_META_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/meta/*.h)

file(GLOB OMC_SIMRT_GC_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/gc/*.c)
file(GLOB OMC_SIMRT_GC_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/gc/*.h)

file(GLOB OMC_SIMRT_FMI_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/fmi/*.c)
file(GLOB OMC_SIMRT_FMI_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/fmi/*.h)

# ######################################################################################################################
# Library: OpenModelicaRuntimeC
add_library(OpenModelicaRuntimeC STATIC)
add_library(omc::simrt::runtime ALIAS OpenModelicaRuntimeC)

target_sources(OpenModelicaRuntimeC PRIVATE ${OMC_SIMRT_UTIL_SOURCES} ${OMC_SIMRT_META_SOURCES} ${OMC_SIMRT_GC_SOURCES})
target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::3rd::omcgc)

if(WIN32)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC dbghelp)
  target_link_libraries(OpenModelicaRuntimeC PUBLIC regex)
endif(WIN32)

target_include_directories(OpenModelicaRuntimeC PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# ######################################################################################################################
# Library: OpenModelicaFMIRuntimeC
add_library(OpenModelicaFMIRuntimeC STATIC ${OMC_SIMRT_FMI_SOURCES})
add_library(omc::simrt::fmiruntime ALIAS OpenModelicaFMIRuntimeC)

target_sources(OpenModelicaFMIRuntimeC PRIVATE ${OMC_SIMRT_FMI_SOURCES})

target_link_libraries(OpenModelicaFMIRuntimeC PUBLIC omc::3rd::fmilib::static)
target_link_libraries(OpenModelicaFMIRuntimeC PUBLIC omc::simrt::runtime)



# Quick and INCOMPLETE generation of RuntimeSources.mo
set(DGESV_FILES \"\")
set(LS_FILES \"\")
set(MIXED_FILES \"\")
set(NLS_FILESCMINPACK_FILES \"\")
# configure_file(${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo.cmake ${CMAKE_CURRENT_SOURCE_DIR}/RuntimeSources.mo)
