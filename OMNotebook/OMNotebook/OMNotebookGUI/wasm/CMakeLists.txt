cmake_minimum_required(VERSION 3.21)

# Standalone Qt-for-WebAssembly build of OMNotebook. Like the OMShell web client
# omc is not linked in process: it runs in the shared omc_worker.js Web Worker
# and omcinteractiveenvironment.cpp bridges to it. OMPlot is built as a library
# only (no OMPlot executable); instead of the whole simulation runtime it uses
# just the result-file readers plus a small stdio shim for omc_file. Configure
# with the Qt wasm toolchain, e.g.
#   <qt-wasm>/bin/qt-cmake -G "Unix Makefiles" -S . -B build
project(OMNotebookQtWasm LANGUAGES C CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS
  Widgets PrintSupport Svg Xml Core5Compat Concurrent OpenGL OpenGLWidgets)
qt_standard_project_setup()

get_filename_component(OM_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../.." ABSOLUTE)
set(NB     ${CMAKE_CURRENT_SOURCE_DIR}/..)
set(OMPLOT ${OM_ROOT}/OMPlot/OMPlot/OMPlotGUI)
set(QWT    ${OM_ROOT}/OMPlot/qwt)
set(SIMRT  ${OM_ROOT}/OMCompiler/SimulationRuntime/c)

# ---- qwt (built static so it links into the single wasm binary) ----
set(USE_QT6 ON CACHE BOOL "" FORCE)
set(QWT_WITH_EXAMPLES OFF CACHE BOOL "" FORCE)
set(OMQWT_LIBRARY_TYPE STATIC)
add_subdirectory(${QWT} ${CMAKE_BINARY_DIR}/qwt)

# ---- OMPlotLib (library only) ----
add_library(OMPlotLib STATIC
  ${OMPLOT}/Plot.cpp
  ${OMPLOT}/PlotZoomer.cpp
  ${OMPLOT}/Legend.cpp
  ${OMPLOT}/PlotPanner.cpp
  ${OMPLOT}/PlotPicker.cpp
  ${OMPLOT}/PlotGrid.cpp
  ${OMPLOT}/PlotCurve.cpp
  ${OMPLOT}/PlotWindow.cpp
  ${OMPLOT}/PlotWindowContainer.cpp
  ${OMPLOT}/PlotMainWindow.cpp
  ${OMPLOT}/ScaleDraw.cpp
  ${OMPLOT}/LogScaleEngine.cpp
  ${OMPLOT}/LinearScaleEngine.cpp
  ${OMPLOT}/resource_omplot.qrc
  # Q_OBJECT classes live in headers whose name differs from the .cpp (e.g. class
  # Plot in OMPlot.h), so AUTOMOC's .cpp/.h pairing misses them; list the headers
  # explicitly — mirrors the native OMPLOTLIB_HEADERS.
  ${OMPLOT}/OMPlot.h
  ${OMPLOT}/PlotZoomer.h
  ${OMPLOT}/Legend.h
  ${OMPLOT}/PlotPanner.h
  ${OMPLOT}/PlotPicker.h
  ${OMPLOT}/PlotGrid.h
  ${OMPLOT}/PlotCurve.h
  ${OMPLOT}/PlotWindow.h
  ${OMPLOT}/PlotWindowContainer.h
  ${OMPLOT}/PlotMainWindow.h
  ${OMPLOT}/ScaleDraw.h
  ${OMPLOT}/LogScaleEngine.h
  ${OMPLOT}/LinearScaleEngine.h
  # result-file readers + a stdio shim, instead of omc::simrt::runtime.
  # omc_numbers.c provides om_strtod (used by read_csv.c).
  ${SIMRT}/util/read_matlab4.c
  ${SIMRT}/util/read_csv.c
  ${SIMRT}/util/libcsv.c
  ${SIMRT}/util/omc_numbers.c
  ${CMAKE_CURRENT_SOURCE_DIR}/omc_file_shim.c)
target_compile_definitions(OMPlotLib PRIVATE OMPLOTLIB_MOC_INCLUDE)
target_include_directories(OMPlotLib PUBLIC ${OMPLOT} PRIVATE ${SIMRT})
target_link_libraries(OMPlotLib PUBLIC
  Qt6::Widgets Qt6::PrintSupport Qt6::Svg Qt6::Core5Compat omqwt)

# ---- OMNotebook ----
# Headers carrying Q_OBJECT / ui_*.h includes (Document, DocumentView, the
# dialogs, …) are defined header-only or have no listed .cpp, so they must be in
# the target sources for AUTOMOC/AUTOUIC to process them — mirrors the native
# OMNOTEBOOKLIB_HEADERS list.
set(OMNOTEBOOK_HEADERS
  ${NB}/ModelicaTextHighlighter.h ${NB}/application.h ${NB}/cell.h
  ${NB}/cellapplication.h ${NB}/cellcommandcenter.h ${NB}/cellcommands.h
  ${NB}/cellcursor.h ${NB}/celldocument.h ${NB}/celldocumentview.h
  ${NB}/cellfactory.h ${NB}/cellgroup.h ${NB}/cellstyle.h
  ${NB}/chaptercountervisitor.h ${NB}/command.h ${NB}/commandcenter.h
  ${NB}/commandcompletion.h ${NB}/commandunit.h ${NB}/cursorcommands.h
  ${NB}/cursorposvisitor.h ${NB}/document.h ${NB}/documentview.h ${NB}/factory.h
  ${NB}/graphcell.h ${NB}/imagesizedlg.h ${NB}/indent.h ${NB}/inputcell.h
  ${NB}/inputcelldelegate.h ${NB}/latexcell.h ${NB}/nbparser.h ${NB}/notebook.h
  ${NB}/notebookcommands.h ${NB}/omcinteractiveenvironment.h ${NB}/otherdlg.h
  ${NB}/parserfactory.h ${NB}/printervisitor.h ${NB}/puretextvisitor.h
  ${NB}/qcombobox_search.h ${NB}/removehighlightervisitor.h
  ${NB}/replaceallvisitor.h ${NB}/resource1.h ${NB}/rule.h ${NB}/searchform.h
  ${NB}/serializingvisitor.h ${NB}/stripstring.h ${NB}/stylesheet.h
  ${NB}/textcell.h ${NB}/textcursorcommands.h ${NB}/treeview.h
  ${NB}/updategroupcellvisitor.h ${NB}/updatelinkvisitor.h ${NB}/visitor.h
  ${NB}/xmlnodename.h ${NB}/xmlparser.h)

qt_add_executable(OMNotebook-qt
  ${NB}/qtapp.cpp
  ${NB}/cellapplication.cpp
  ${NB}/cellparserfactory.cpp
  ${NB}/stylesheet.cpp
  ${NB}/cellcommandcenter.cpp
  ${NB}/chaptercountervisitor.cpp
  ${NB}/omcinteractiveenvironment.cpp
  ${NB}/textcell.cpp
  ${NB}/cellcommands.cpp
  ${NB}/commandcompletion.cpp
  ${NB}/ModelicaTextHighlighter.cpp
  ${NB}/textcursorcommands.cpp
  ${NB}/cell.cpp
  ${NB}/printervisitor.cpp
  ${NB}/treeview.cpp
  ${NB}/cellcursor.cpp
  ${NB}/puretextvisitor.cpp
  ${NB}/updategroupcellvisitor.cpp
  ${NB}/celldocument.cpp
  ${NB}/inputcell.cpp
  ${NB}/qcombobox_search.cpp
  ${NB}/updatelinkvisitor.cpp
  ${NB}/cellfactory.cpp
  ${NB}/notebook.cpp
  ${NB}/xmlparser.cpp
  ${NB}/searchform.cpp
  ${NB}/cellgroup.cpp
  ${NB}/serializingvisitor.cpp
  ${NB}/graphcell.cpp
  ${NB}/latexcell.cpp
  ${NB}/indent.cpp
  ${OMNOTEBOOK_HEADERS}
  ${NB}/res_qt.qrc)
target_compile_definitions(OMNotebook-qt PRIVATE OMNOTEBOOKLIB_MOC_INCLUDE)
target_include_directories(OMNotebook-qt PRIVATE ${NB})
target_link_libraries(OMNotebook-qt PRIVATE
  OMPlotLib Qt6::Widgets Qt6::Xml Qt6::PrintSupport Qt6::Core5Compat)

target_link_options(OMNotebook-qt PRIVATE
  -sASYNCIFY
  -sASYNCIFY_STACK_SIZE=131072
  -sALLOW_MEMORY_GROWTH=1
  -sEXPORTED_RUNTIME_METHODS=UTF8ToString,stringToNewUTF8,FS)
