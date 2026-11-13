

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
                      PlotTranslator.cpp
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
                      LinearScaleEngine.h
                      PlotTranslator.h)

# Translations. OMPlot translates its own strings, the programs using OMPlotLib (OMEdit, OMNotebook
# and OMPlot) load OMPlot_<locale>.qm from <omhome>/share/omplot/nls, see PlotTranslator.h.
# The languages are the ones of OMEdit.
find_package(Qt6 REQUIRED COMPONENTS LinguistTools)
set(OMPLOT_TS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_de.ts
                    ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_es.ts
                    ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_fr.ts
                    ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_it.ts
                    ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_ja.ts
                    ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_ro.ts
                    ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_ru.ts
                    ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_sv.ts
                    ${CMAKE_CURRENT_SOURCE_DIR}/Resources/nls/OMPlot_zh_CN.ts)
qt_add_translation(OMPLOT_TRANSLATIONS ${OMPLOT_TS_FILES})

add_library(OMPlotLib SHARED ${OMPLOTLIB_SOURCES} ${OMPLOTLIB_HEADERS} ${OMPLOT_TRANSLATIONS})

# Update the .ts files (see OM_UPDATE_TRANSLATIONS).
set(OMPLOT_LUPDATE_SOURCES ${OMPLOTLIB_SOURCES} ${OMPLOTLIB_HEADERS} main.cpp)
list(TRANSFORM OMPLOT_LUPDATE_SOURCES PREPEND "${CMAKE_CURRENT_SOURCE_DIR}/")
omc_add_qt_lupdate(OMPlotLib TS_FILES ${OMPLOT_TS_FILES} SOURCES ${OMPLOT_LUPDATE_SOURCES})

target_compile_definitions(OMPlotLib PRIVATE OMPLOTLIB_MOC_INCLUDE OMPLOTLIB_LIBRARY)

if(MSVC)
  set_target_properties(OMPlotLib PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS true)
endif()

target_include_directories(OMPlotLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(OMPlotLib PUBLIC Qt6::Widgets)
target_link_libraries(OMPlotLib PUBLIC Qt6::PrintSupport)
target_link_libraries(OMPlotLib PUBLIC Qt6::Svg)

target_link_libraries(OMPlotLib PUBLIC Qt6::Core5Compat)

target_link_libraries(OMPlotLib PUBLIC omqwt)
target_link_libraries(OMPlotLib PUBLIC omc::result)

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
install(FILES ${OMPLOT_TRANSLATIONS}
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omplot/nls)
omc_install_gui_client(OMPlot)

if(MINGW)
  omc_get_msys_prefix(MSYSTEM_PREFIX_ESCAPED)

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
        --translationdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/share/qt6/translations\"
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
