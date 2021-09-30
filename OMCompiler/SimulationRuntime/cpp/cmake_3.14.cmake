
project(SimRT_CPP)

add_definitions(-DOMC_BUILD)

configure_file (${CMAKE_CURRENT_SOURCE_DIR}/LibrariesConfig.h.in ${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h )

add_library(OMCppConfig INTERFACE)
add_library(omc::simrt::cpp::config ALIAS OMCppConfig)

target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/Include)

add_subdirectory(Core)
add_subdirectory(Solver)
