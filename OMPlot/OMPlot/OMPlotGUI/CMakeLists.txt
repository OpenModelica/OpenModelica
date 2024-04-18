

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
target_compile_definitions(OMPlotLib PRIVATE OMPLOTLIB_MOC_INCLUDE)

if(MSVC)
  set_target_properties(OMPlotLib PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()

target_include_directories(OMPlotLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(OMPlotLib PUBLIC Qt5::Widgets)
target_link_libraries(OMPlotLib PUBLIC Qt5::PrintSupport)
target_link_libraries(OMPlotLib PUBLIC omqwt)
target_link_libraries(OMPlotLib PUBLIC omc::simrt::runtime)



if(APPLE)
  set(MACOSX_BUNDLE_ICON_FILE omplot.ico)

  # The following tells CMake where to find and install the file itself.
  set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/Resources/icons/omplot.ico")
  set_source_files_properties(${app_icon_macos} PROPERTIES
       MACOSX_PACKAGE_LOCATION "Resources")
else()
  set(app_icon_macos "")
endif()

add_executable(OMPlot WIN32 MACOSX_BUNDLE main.cpp rc_omplot.rc ${app_icon_macos})
target_link_libraries(OMPlot PRIVATE OMPlotLib)


install(TARGETS OMPlotLib)
install(TARGETS OMPlot
        BUNDLE DESTINATION ${OM_MACOS_INSTALL_BUNDLEDIR})
