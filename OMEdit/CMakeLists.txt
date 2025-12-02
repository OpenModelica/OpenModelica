cmake_minimum_required (VERSION 3.14)

project(OMEdit)
## Anything installed from this directory and its subdirectories belongs
## to the install component 'omedit' if it is not explicitly changed.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omedit)

omc_option(OM_OMEDIT_INSTALL_RUNTIME_DLLS "Install the required runtime dll dependency DLLs to the binary directory. Valid only for Windows builds." ON)
omc_option(OM_OMEDIT_ENABLE_TESTS "Enable building of OMEdit Testsuite tests." OFF)
omc_option(OM_OMEDIT_ENABLE_QTWEBENGINE "Enable building of OMEdit with QtWebEngine instead of QtWebkit" OFF)

find_package(Qt${OM_QT_MAJOR_VERSION} COMPONENTS Widgets PrintSupport Xml OpenGL Network Svg REQUIRED)

if (OM_OMEDIT_ENABLE_QTWEBENGINE OR OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  find_package(Qt${OM_QT_MAJOR_VERSION} COMPONENTS WebEngineWidgets REQUIRED)
else ()
  find_package(Qt${OM_QT_MAJOR_VERSION} COMPONENTS WebKitWidgets REQUIRED)
endif ()

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  find_package(Qt6 COMPONENTS OpenGLWidgets Core5Compat REQUIRED)
endif ()

find_package(OpenSceneGraph COMPONENTS osg osgViewer osgUtil osgDB osgGA REQUIRED)
find_package(OpenGL REQUIRED)

# Configure omedit_config.h. This will be generated in the build directory
configure_file(omedit_config.h.in omedit_config.h)
## Add a config library for OMEdit. It will provide access to common config headres such as
## config.h. So by linking to this library you get the include directories.
add_library(omedit_config INTERFACE)
add_library(omedit::config ALIAS omedit_config)
target_include_directories(omedit_config INTERFACE ${CMAKE_CURRENT_BINARY_DIR})

omc_add_subdirectory(OMEditLIB)
omc_add_subdirectory(OMEditGUI)

if(OM_OMEDIT_ENABLE_TESTS)
  omc_add_subdirectory(Testsuite)
endif()
