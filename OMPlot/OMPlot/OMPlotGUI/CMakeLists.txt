

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
                      ScaleDraw.h)

add_library(OMPlotLib SHARED ${OMPLOTLIB_SOURCES} ${OMPLOTLIB_HEADERS})
target_compile_definitions(OMPlotLib PRIVATE OMPLOTLIB_MOC_INCLUDE)

target_include_directories(OMPlotLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(OMPlotLib PUBLIC Qt5::Widgets)
target_link_libraries(OMPlotLib PUBLIC Qt5::PrintSupport)
target_link_libraries(OMPlotLib PUBLIC qwt)
target_link_libraries(OMPlotLib PUBLIC omc::simrt::runtime)

target_link_options(OMPlotLib PRIVATE -Wl,--no-undefined)


add_executable(OMPlot main.cpp rc_omplot.rc)
target_link_libraries(OMPlot PRIVATE OMPlotLib)

install(TARGETS OMPlotLib)
install(TARGETS OMPlot)
