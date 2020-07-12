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


set(libOpenModelicaRuntimeC_BUILD_TYPE STATIC CACHE STRING "Type of OpenModelicaRuntimeC to build")
omc_add_to_report(libOpenModelicaRuntimeC_BUILD_TYPE)

add_library(OpenModelicaRuntimeC ${libOpenModelicaRuntimeC_BUILD_TYPE}
                                    ${OMC_SIMRT_UTIL_SOURCES}
                                    ${OMC_SIMRT_META_SOURCES}
                                    ${OMC_SIMRT_GC_SOURCES})
target_link_libraries(OpenModelicaRuntimeC PUBLIC omc::3rd::gc regex dbghelp)
target_compile_options(OpenModelicaRuntimeC PRIVATE $<$<CXX_COMPILER_ID:GNU>:-Werror=implicit-function-declaration>)
# target_link_libraries(OpenModelicaRuntimeC PUBLIC $<$<CXX_COMPILER_ID:gcc>:dbghelp>)



set(libOpenModelicaFMIRuntimeC_BUILD_TYPE STATIC CACHE STRING "Type of OpenModelicaFMIRuntimeC to build" FORCE)
omc_add_to_report(libOpenModelicaFMIRuntimeC_BUILD_TYPE)

add_library(OpenModelicaFMIRuntimeC ${libOpenModelicaFMIRuntimeC_BUILD_TYPE}
                                    ${OMC_SIMRT_FMI_SOURCES})


target_link_libraries(OpenModelicaFMIRuntimeC PUBLIC omc::3rd::fmilib::shared)
target_link_libraries(OpenModelicaFMIRuntimeC PUBLIC OpenModelicaRuntimeC)
target_compile_options(OpenModelicaFMIRuntimeC PRIVATE $<$<CXX_COMPILER_ID:GNU>:-Werror=implicit-function-declaration>)

