cmake_minimum_required (VERSION 3.14)

project(OMEdit)

## Set the C++ standard to use.
set(CMAKE_CXX_STANDARD 14)
set(CXX_STANDARD_REQUIRED ON)
## Make sure we do not start relying on extensions down the road.
set(CMAKE_CXX_EXTENSIONS OFF)


find_package(Qt5 COMPONENTS Widgets PrintSupport WebKitWidgets Xml XmlPatterns OpenGL Network Svg REQUIRED)
find_package(OpenSceneGraph COMPONENTS osgViewer osgDB osgGA REQUIRED)

# Configure omedit_config.h. This will be generated in the build directory
configure_file(omedit_config.h.in omedit_config.h)
## Add a config library for OMEdit. They will provide access to common config headres such as
## config.h. So by linking to this library you get the include directories.
add_library(omedit_config INTERFACE)
add_library(omedit::config ALIAS omedit_config)
target_include_directories(omedit_config INTERFACE ${CMAKE_CURRENT_BINARY_DIR})

omc_add_subdirectory(OMEditLIB)
omc_add_subdirectory(OMEditGUI)

