

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

target_link_libraries(OMPlotLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Widgets)
target_link_libraries(OMPlotLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::PrintSupport)
target_link_libraries(OMPlotLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Svg)

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMPlotLib PUBLIC Qt6::Core5Compat)
endif ()

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

add_executable(OMPlot WIN32 main.cpp rc_omplot.rc ${app_icon_macos})
target_link_libraries(OMPlot PRIVATE OMPlotLib)

install(TARGETS OMPlotLib)
omc_install_gui_client(OMPlot)

if(MINGW)
  # Find windeployqt6
  find_program(WINDEPLOYQT_EXECUTABLE
    NAMES windeployqt windeployqt6
    HINTS "${MSYSTEM_PREFIX_ESCAPED}/bin"
    REQUIRED
  )

  install(CODE "
    message(STATUS \"Running windeployqt6 on OMPlot...\")
    execute_process(
      COMMAND \"${WINDEPLOYQT_EXECUTABLE}\"
        --no-compiler-runtime
        --no-system-d3d-compiler
        --no-quick-import
        --libdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\"
        \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/OMPlot.exe\"
      RESULT_VARIABLE WINDEPLOYQT_RESULT
      OUTPUT_VARIABLE WINDEPLOYQT_OUTPUT
      ERROR_VARIABLE  WINDEPLOYQT_ERROR
    )
    if(NOT WINDEPLOYQT_RESULT EQUAL 0)
      message(FATAL_ERROR \"windeployqt6 failed:\n\${WINDEPLOYQT_OUTPUT}\n\${WINDEPLOYQT_ERROR}\")
    endif()
    message(STATUS \"windeployqt6 output: \${WINDEPLOYQT_OUTPUT}\")
  ")
endif()
