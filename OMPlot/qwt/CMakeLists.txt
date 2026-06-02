# Taken from https://github.com/xantares/qwt-cmake and modified for
# qwt 6.1.5 and OpenModelica

cmake_minimum_required (VERSION 3.14)
project (omqwt VERSION 6.1.5 LANGUAGES CXX)

option (QWT_WITH_PLOT "Whether to build plot" ON)
option (QWT_WITH_SVG "Whether to build svg" ON)
option (QWT_WITH_OPENGL "Whether to build opengl" ON)
option (QWT_WITH_WIDGETS "Whether to build widgets" ON)

option (QWT_WITH_EXAMPLES "Whether to include examples" OFF)


option (USE_QT6 "qt 6.x" OFF)
if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  set (USE_QT6 ON CACHE BOOL "qt 6.x" FORCE)
endif ()

set (QWT_VER_MAJ 6)
set (QWT_VER_MIN 1)
set (QWT_VER_PAT 5)
set (QWT_VERSION ${QWT_VER_MAJ}.${QWT_VER_MIN}.${QWT_VER_PAT})

if (USE_QT6)
  find_package (Qt6 COMPONENTS Concurrent OpenGL OpenGLWidgets PrintSupport Svg Widgets REQUIRED CONFIG)
else ()
  find_package (Qt5 COMPONENTS Concurrent OpenGL PrintSupport Svg Widgets REQUIRED CONFIG)
endif ()

add_subdirectory (src)

if (WITH_EXAMPLES)
  add_subdirectory(examples)
endif()
