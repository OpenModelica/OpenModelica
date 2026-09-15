

set(OMPLOTLIB_SOURCES Plot.cpp
                      PlotZoomer.cpp
                      Legend.cpp
                      PlotPanner.cpp
                      PlotPicker.cpp
                      PlotGrid.cpp
                      PlotCurve.cpp
                      PlotWindow.cpp
                      PlotApplication.cpp
                      PlotWindowContainer.cpp
                      PlotMainWindow.cpp
                      ScaleDraw.cpp
                      LogScaleEngine.cpp
                      LinearScaleEngine.cpp
                      resource_omplot.qrc)

set(OMPLOTLIB_HEADERS OMPlot.h
                      PlotZoomer.h
                      Legend.h
                      PlotPanner.h
                      PlotPicker.h
                      PlotGrid.h
                      PlotCurve.h
                      PlotWindow.h
                      PlotApplication.h
                      PlotWindowContainer.h
                      PlotMainWindow.h
                      ScaleDraw.h
                      LogScaleEngine.h
                      LinearScaleEngine.h)

add_library(OMPlotLib SHARED ${OMPLOTLIB_SOURCES} ${OMPLOTLIB_HEADERS})
target_compile_definitions(OMPlotLib PRIVATE OMPLOTLIB_MOC_INCLUDE OMPLOTLIB_LIBRARY)

if(MSVC)
  set_target_properties(OMPlotLib PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()

target_include_directories(OMPlotLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(OMPlotLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Widgets)
target_link_libraries(OMPlotLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::PrintSupport)
target_link_libraries(OMPlotLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Svg)

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMPlotLib PUBLIC Qt6::Core5Compat)
endif ()

target_link_libraries(OMPlotLib PUBLIC omqwt)
# OMPlotLib calls the result-reader helpers (read_matlab4/read_csv/omc_matlab4_*)
# internally. On MSVC those are DLLDirection-exported from OpenModelicaCompiler.dll
# and OMPlotLib is compiled with IMPORT_INTO, so link OpenModelicaCompiler (its
# import lib) rather than absorbing a second static copy of OpenModelicaRuntimeC -
# a copy that OMEdit, which links both DLLs, would otherwise see twice. Elsewhere
# OpenModelicaRuntimeC is itself a shared library, so the plain runtime link is
# fine and kept.
if(MSVC)
  target_link_libraries(OMPlotLib PUBLIC OpenModelicaCompiler)
else()
  target_link_libraries(OMPlotLib PUBLIC omc::simrt::runtime)
endif()
# Result files: the Rust omc_result library (also opens .arrow), or the C readers.
# PUBLIC, so OMEdit (which links OMPlotLib) follows the same choice.
if(OM_RUST_RESULT_READERS)
  target_link_libraries(OMPlotLib PUBLIC omc::result)
else()
  target_compile_definitions(OMPlotLib PUBLIC OM_LEGACY_RESULT_READERS)
endif()

if(APPLE)
  set(MACOSX_BUNDLE_ICON_FILE omplot.ico)

  # The following tells CMake where to find and install the file itself.
  set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/Resources/icons/omplot.ico")
  set_source_files_properties(${app_icon_macos} PROPERTIES
       MACOSX_PACKAGE_LOCATION "Resources")
else()
  set(app_icon_macos "")
endif()

add_executable(OMPlot WIN32 main.cpp rc_omplot.rc ${app_icon_macos})
target_link_libraries(OMPlot PRIVATE OMPlotLib)

install(TARGETS OMPlotLib)
omc_install_gui_client(OMPlot)

# Bundle the Qt runtime next to OMPlot.exe: MinGW/MSYS2 and native MSVC.
if(MINGW OR (MSVC AND NOT CMAKE_CROSSCOMPILING))
  omc_windeployqt(OMPlot)
endif()
