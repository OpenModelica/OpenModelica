# Shaped after Modelica/Resources/CMakeLists.txt, the entry point a tool runs.
cmake_minimum_required(VERSION 3.11...3.31)
project(BuildProjectTestLib VERSION 1.0.0 LANGUAGES C)

set(MODELICA_RESOURCES_DIR "${PROJECT_SOURCE_DIR}")

include(BuildProjects/CMake/Modelica_platform.cmake)
include(BuildProjects/CMake/Modelica_utilities.cmake)

if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
  set(CMAKE_INSTALL_PREFIX "${MODELICA_RESOURCES_DIR}" CACHE PATH
      "Library installation prefix path (don't change)" FORCE)
endif()

get_modelica_platform_name(MODELICA_PLATFORM_NAME)
set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_PREFIX}/Library/${MODELICA_PLATFORM_NAME}"
    CACHE PATH "Library installation path (don't change)" FORCE)

# No STATIC, unlike the MSL: a wasm target loads a module and asks for it with
# BUILD_SHARED_LIBS.
add_library(BuildProjectTestLib "${MODELICA_RESOURCES_DIR}/C-Sources/BuildProjectTestLib.c")
target_include_directories(BuildProjectTestLib PUBLIC "${MODELICA_RESOURCES_DIR}/Include")
set_target_properties(BuildProjectTestLib PROPERTIES POSITION_INDEPENDENT_CODE ON)

install(TARGETS BuildProjectTestLib
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")
