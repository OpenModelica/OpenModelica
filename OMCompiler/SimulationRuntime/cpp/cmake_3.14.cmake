
project(SimRT_CPP)

add_definitions(-DOMC_BUILD)

# CPP libs should be installed to in lib/<arch>/omc/cpp/ for now.
set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR}/cpp)
# CPP headers are installed in include/omc/cpp for now.
set(CMAKE_INSTALL_INCLUDEDIR ${CMAKE_INSTALL_INCLUDEDIR}/omc/cpp)


configure_file(${CMAKE_CURRENT_SOURCE_DIR}/LibrariesConfig.h.in ${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h)

install(FILES ${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h
        TYPE INCLUDE)


# An interface library for providing common include directories for all the CPP libs.
add_library(OMCppConfig INTERFACE)
add_library(omc::simrt::cpp::config ALIAS OMCppConfig)

target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_BINARY_DIR})
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
target_include_directories(OMCppConfig INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/Include)


# Subdirectories
add_subdirectory(SimCoreFactory)
add_subdirectory(Core)
add_subdirectory(Solver)


# This folder contains only one file right now. Something should be done about it.
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/Include/
         TYPE INCLUDE)

