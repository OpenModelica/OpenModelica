# file(GLOB_RECURSE OMEDITLIB_HEADERS ${CMAKE_CURRENT_SOURCE_DIR}/*.h)

# file(GLOB_RECURSE OMEDITLIB_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)
# set(OMEDITLIB_SOURCES resource_omedit.qrc ${OMEDITLIB_SOURCES})


# This small module (OpenModelica/cmake/modules/Findbinutils.cmake) finds and sets up
# libbfd which is need for providing bactrace support for OMEdit.
# It is required always on MinGW for now. Can be made optional with some changes.
if(MINGW)
  find_package(binutils REQUIRED)
endif()


omc_add_subdirectory(Debugger/Parser)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

set(OMEDITLIB_SOURCES Util/Helper.cpp
                      Util/Utilities.cpp
                      Util/StringHandler.cpp
                      Util/OutputPlainTextEdit.cpp
                      Util/PathSelector.cpp
                      MainWindow.cpp
                      OMC/OMCProxy.cpp
                      Modeling/Model.cpp
                      Modeling/MessagesWidget.cpp
                      Modeling/ItemDelegate.cpp
                      Modeling/LibraryTreeWidget.cpp
                      Modeling/ElementTreeWidget.cpp
                      Modeling/Commands.cpp
                      Modeling/ModelWidgetContainer.cpp
                      Modeling/ModelicaClassDialog.cpp
                      Modeling/FunctionArgumentDialog.cpp
                      Modeling/InstallLibraryDialog.cpp
                      Search/SearchWidget.cpp
                      Options/OptionsDialog.cpp
                      Editors/BaseEditor.cpp
                      Editors/ModelicaEditor.cpp
                      Editors/TransformationsEditor.cpp
                      Editors/TextEditor.cpp
                      Editors/CEditor.cpp
                      Editors/CRMLEditor.cpp
                      Editors/OMSimulatorEditor.cpp
                      Editors/MetaModelicaEditor.cpp
                      Editors/HTMLEditor.cpp
                      Plotting/PlotWindowContainer.cpp
                      Element/Element.cpp
                      Annotations/ShapeAnnotation.cpp
                      Element/CornerItem.cpp
                      Annotations/LineAnnotation.cpp
                      Annotations/PolygonAnnotation.cpp
                      Annotations/RectangleAnnotation.cpp
                      Annotations/EllipseAnnotation.cpp
                      Annotations/TextAnnotation.cpp
                      Annotations/BitmapAnnotation.cpp
                      Annotations/DynamicAnnotation.cpp
                      Annotations/BooleanAnnotation.cpp
                      Annotations/PointAnnotation.cpp
                      Annotations/RealAnnotation.cpp
                      Annotations/ColorAnnotation.cpp
                      Annotations/LinePatternAnnotation.cpp
                      Annotations/FillPatternAnnotation.cpp
                      Annotations/PointArrayAnnotation.cpp
                      Annotations/ArrowAnnotation.cpp
                      Annotations/SmoothAnnotation.cpp
                      Annotations/ExtentAnnotation.cpp
                      Annotations/BorderPatternAnnotation.cpp
                      Annotations/EllipseClosureAnnotation.cpp
                      Annotations/StringAnnotation.cpp
                      Annotations/TextAlignmentAnnotation.cpp
                      Annotations/TextStyleAnnotation.cpp
                      Element/ElementProperties.cpp
                      Element/Transformation.cpp
                      Modeling/DocumentationWidget.cpp
                      Simulation/TranslationFlagsWidget.cpp
                      Simulation/SimulationDialog.cpp
                      Simulation/SimulationOutputWidget.cpp
                      Simulation/SimulationOutputHandler.cpp
                      Simulation/OpcUaClient.cpp
                      Simulation/ArchivedSimulationsWidget.cpp
                      FMI/ImportFMUDialog.cpp
                      FMI/ImportFMUModelDescriptionDialog.cpp
                      FMI/FMUExportOutputWidget.cpp
                      Plotting/VariablesWidget.cpp
                      Plotting/DiagramWindow.cpp
                      Options/NotificationsDialog.cpp
                      Annotations/ShapePropertiesDialog.cpp
                      TransformationalDebugger/OMDumpXML.cpp
                      TransformationalDebugger/diff_match_patch.cpp
                      TransformationalDebugger/TransformationsWidget.cpp
                      Debugger/GDB/CommandFactory.cpp
                      Debugger/GDB/GDBAdapter.cpp
                      Debugger/StackFrames/StackFramesWidget.cpp
                      Debugger/Locals/LocalsWidget.cpp
                      Debugger/Locals/ModelicaValue.cpp
                      Debugger/Breakpoints/BreakpointMarker.cpp
                      Debugger/Breakpoints/BreakpointsWidget.cpp
                      Debugger/Breakpoints/BreakpointDialog.cpp
                      Debugger/DebuggerConfigurationsDialog.cpp
                      Debugger/Attach/AttachToProcessDialog.cpp
                      Debugger/Attach/ProcessListModel.cpp
                      CrashReport/backtrace.c
                      CrashReport/GDBBacktrace.cpp
                      CrashReport/CrashReportDialog.cpp
                      CRML/CRMLModelDialog.cpp
                      CRML/CRMLProxy.cpp
                      Git/GitCommands.cpp
                      Git/CommitChangesDialog.cpp
                      Git/RevertCommitsDialog.cpp
                      Git/CleanDialog.cpp
                      OMEditApplication.cpp
                      Traceability/TraceabilityGraphViewWidget.cpp
                      Traceability/TraceabilityInformationURI.cpp
                      OMS/OMSProxy.cpp
                      OMS/ModelDialog.cpp
                      OMS/BusDialog.cpp
                      OMS/ElementPropertiesDialog.cpp
                      OMS/SystemSimulationInformationDialog.cpp
                      OMS/OMSSimulationDialog.cpp
                      OMS/OMSSimulationOutputWidget.cpp
                      Animation/TimeManager.cpp
                      Util/ResourceCache.cpp
                      Util/NetworkAccessManager.cpp
                      FlatModelica/Expression.cpp
                      FlatModelica/ExpressionFuncs.cpp
                      FlatModelica/Parser.cpp
                      Animation/OpenGLWidget.cpp
                      Animation/AbstractAnimationWindow.cpp
                      Animation/ViewerWidget.cpp
                      Animation/AnimationWindow.cpp
                      Animation/ThreeDViewer.cpp
                      Animation/ExtraShapes.cpp
                      Animation/Visualization.cpp
                      Animation/VisualizationMAT.cpp
                      Animation/VisualizationCSV.cpp
                      Animation/VisualizationFMU.cpp
                      Animation/FMUSettingsDialog.cpp
                      Animation/FMUWrapper.cpp
                      Animation/AbstractVisualizer.cpp
                      Animation/Shape.cpp
                      Animation/Vector.cpp
                      resource_omedit.qrc)


set(OMEDITLIB_HEADERS Util/Helper.h
                      Util/Utilities.h
                      Util/StringHandler.h
                      Util/OutputPlainTextEdit.h
                      Util/PathSelector.h
                      MainWindow.h
                      OMC/OMCProxy.h
                      Modeling/Model.h
                      Modeling/MessagesWidget.h
                      Modeling/ItemDelegate.h
                      Modeling/LibraryTreeWidget.h
                      Modeling/ElementTreeWidget.h
                      Modeling/Commands.h
                      Modeling/ModelWidgetContainer.h
                      Modeling/ModelicaClassDialog.h
                      Modeling/FunctionArgumentDialog.h
                      Modeling/InstallLibraryDialog.h
                      Search/SearchWidget.h
                      Options/OptionsDefaults.h
                      Options/OptionsDialog.h
                      Editors/BaseEditor.h
                      Editors/ModelicaEditor.h
                      Editors/TransformationsEditor.h
                      Editors/TextEditor.h
                      Editors/CEditor.h
                      Editors/CRMLEditor.h
                      Editors/OMSimulatorEditor.h
                      Editors/MetaModelicaEditor.h
                      Editors/HTMLEditor.h
                      Plotting/PlotWindowContainer.h
                      Element/Element.h
                      Annotations/ShapeAnnotation.h
                      Element/CornerItem.h
                      Annotations/LineAnnotation.h
                      Annotations/PolygonAnnotation.h
                      Annotations/RectangleAnnotation.h
                      Annotations/EllipseAnnotation.h
                      Annotations/TextAnnotation.h
                      Annotations/BitmapAnnotation.h
                      Annotations/DynamicAnnotation.h
                      Annotations/BooleanAnnotation.h
                      Annotations/PointAnnotation.h
                      Annotations/RealAnnotation.h
                      Annotations/ColorAnnotation.h
                      Annotations/LinePatternAnnotation.h
                      Annotations/FillPatternAnnotation.h
                      Annotations/PointArrayAnnotation.h
                      Annotations/ArrowAnnotation.h
                      Annotations/SmoothAnnotation.h
                      Annotations/ExtentAnnotation.h
                      Annotations/BorderPatternAnnotation.h
                      Annotations/EllipseClosureAnnotation.h
                      Annotations/StringAnnotation.h
                      Annotations/TextAlignmentAnnotation.h
                      Annotations/TextStyleAnnotation.h
                      Element/ElementProperties.h
                      Element/Transformation.h
                      Modeling/DocumentationWidget.h
                      Simulation/SimulationOptions.h
                      Simulation/TranslationFlagsWidget.h
                      Simulation/SimulationDialog.h
                      Simulation/SimulationOutputWidget.h
                      Simulation/SimulationOutputHandler.h
                      Simulation/OpcUaClient.h
                      Simulation/ArchivedSimulationsWidget.h
                      FMI/ImportFMUDialog.h
                      FMI/ImportFMUModelDescriptionDialog.h
                      FMI/FMUExportOutputWidget.h
                      Plotting/VariablesWidget.h
                      Plotting/DiagramWindow.h
                      Options/NotificationsDialog.h
                      Annotations/ShapePropertiesDialog.h
                      TransformationalDebugger/OMDumpXML.cpp
                      TransformationalDebugger/diff_match_patch.h
                      TransformationalDebugger/TransformationsWidget.h
                      Debugger/GDB/CommandFactory.h
                      Debugger/GDB/GDBAdapter.h
                      Debugger/StackFrames/StackFramesWidget.h
                      Debugger/Locals/LocalsWidget.h
                      Debugger/Locals/ModelicaValue.h
                      Debugger/Breakpoints/BreakpointMarker.h
                      Debugger/Breakpoints/BreakpointsWidget.h
                      Debugger/Breakpoints/BreakpointDialog.h
                      Debugger/DebuggerConfigurationsDialog.h
                      Debugger/Attach/AttachToProcessDialog.h
                      Debugger/Attach/ProcessListModel.h
                      CrashReport/backtrace.h
                      CrashReport/GDBBacktrace.h
                      CrashReport/CrashReportDialog.h
                      CRML/CRMLProxy.h
                      CRML/CRMLModelDialog.h
                      Git/GitCommands.h
                      Git/CommitChangesDialog.h
                      Git/RevertCommitsDialog.h
                      Git/CleanDialog.h
                      OMEditApplication.h
                      Traceability/TraceabilityGraphViewWidget.h
                      Traceability/TraceabilityInformationURI.h
                      OMS/OMSProxy.h
                      OMS/ModelDialog.h
                      OMS/BusDialog.h
                      OMS/ElementPropertiesDialog.h
                      OMS/SystemSimulationInformationDialog.h
                      OMS/OMSSimulationDialog.h
                      OMS/OMSSimulationOutputWidget.h
                      Animation/TimeManager.h
                      Interfaces/InformationInterface.h
                      Interfaces/ModelInterface.h
                      Util/ResourceCache.h
                      Util/NetworkAccessManager.h
                      FlatModelica/Expression.h
                      FlatModelica/ExpressionFuncs.h
                      FlatModelica/Parser.h
                      Animation/OpenGLWidget.h
                      Animation/AbstractAnimationWindow.h
                      Animation/ViewerWidget.h
                      Animation/AnimationWindow.h
                      Animation/ThreeDViewer.h
                      Animation/AnimationUtil.h
                      Animation/ExtraShapes.h
                      Animation/Visualization.h
                      Animation/VisualizationMAT.h
                      Animation/VisualizationCSV.h
                      Animation/VisualizationFMU.h
                      Animation/FMUSettingsDialog.h
                      Animation/FMUWrapper.h
                      Animation/AbstractVisualizer.h
                      Animation/Shape.h
                      Animation/Vector.h
                      Animation/rapidxml.hpp)


# Add the OpenModelica generated files to sources
set(OMEDITLIB_HEADERS ${OMEDITLIB_HEADERS} ${OMCompiler_SOURCE_DIR}/Compiler/Script/OpenModelicaScriptingAPIQt.h)
set(OMEDITLIB_SOURCES ${OMEDITLIB_SOURCES} ${OMCompiler_SOURCE_DIR}/Compiler/Script/OpenModelicaScriptingAPIQt.cpp)
# Even though these are outputs of CMake custom commands, cmake fails to automatically recognize them as generated.
# My guess is that the directory difference is confusing it. So maunally mark them as generated.
set_source_files_properties(${OMCompiler_SOURCE_DIR}/Compiler/Script/OpenModelicaScriptingAPIQt.cpp GENERATED)
set_source_files_properties(${OMCompiler_SOURCE_DIR}/Compiler/Script/OpenModelicaScriptingAPIQt.h GENERATED)

add_library(OMEditLib STATIC ${OMEDITLIB_SOURCES} ${OMEDITLIB_HEADERS})

target_include_directories(OMEditLib PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
# OpenSceneGraph does not provide imported targets yet. Add includes manually.
target_include_directories(OMEditLib PUBLIC ${OPENSCENEGRAPH_INCLUDE_DIRS})

# qmake adds -DUNICODE by defult (As far as I can gather).
# So add it for CMake as well to avoid having to modify the code.
if(WIN32)
  target_compile_definitions(OMEditLib PRIVATE UNICODE)
endif()

if(OM_ENABLE_ENCRYPTION)
  target_compile_definitions(OMEditLib PRIVATE OM_ENABLE_ENCRYPTION)
endif()

target_link_libraries(OMEditLib PUBLIC omedit::config)
target_link_libraries(OMEditLib PUBLIC OMSimulatorLib)
target_link_libraries(OMEditLib PUBLIC OMParser)
target_link_libraries(OMEditLib PUBLIC omedit::debugger::parser)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Xml)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Widgets)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::PrintSupport)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::OpenGL)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Network)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Svg)

if (OM_OMEDIT_ENABLE_QTWEBENGINE OR OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::WebEngineWidgets)
  target_compile_definitions(OMEditLib PUBLIC OM_OMEDIT_ENABLE_QTWEBENGINE)
else ()
  target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::WebKitWidgets)
endif ()

if (OM_OMEDIT_ENABLE_LIBXML2 OR OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMEditLib PUBLIC LibXml2::LibXml2)
  target_compile_definitions(OMEditLib PUBLIC OM_OMEDIT_ENABLE_LIBXML2)
else ()
  target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::XmlPatterns)
endif ()

target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::OpenGL)
if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::OpenGLWidgets)
endif ()
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Network)
target_link_libraries(OMEditLib PUBLIC Qt${OM_QT_MAJOR_VERSION}::Svg)

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  target_link_libraries(OMEditLib PUBLIC Qt6::Core5Compat)
endif ()

target_link_libraries(OMEditLib PUBLIC omc::3rd::opcua)
target_link_libraries(OMEditLib PUBLIC OMPlotLib)
target_link_libraries(OMEditLib PUBLIC OpenModelicaCompiler)
target_link_libraries(OMEditLib PUBLIC ${OPENSCENEGRAPH_LIBRARIES})
target_link_libraries(OMEditLib PUBLIC OpenGL::GL)

# Silence OpenGL deprecation warnings on macOS
if(APPLE)
  target_compile_definitions(OMEditLib PRIVATE GL_SILENCE_DEPRECATION)
endif()

if(MINGW)
  target_link_libraries(OMEditLib PUBLIC binutils::bfd)
  target_link_libraries(OMEditLib PUBLIC zlib)
endif()

target_include_directories(OMEditLib PUBLIC ${OMCompiler_SOURCE_DIR}/Compiler/Script)

# Install the translation files
install(DIRECTORY Resources/nls
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omedit/
        FILES_MATCHING PATTERN "*.qm")
