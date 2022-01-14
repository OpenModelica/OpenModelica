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
                      MainWindow.cpp
                      OMC/OMCProxy.cpp
                      Modeling/MessagesWidget.cpp
                      Modeling/ItemDelegate.cpp
                      Modeling/LibraryTreeWidget.cpp
                      Modeling/Commands.cpp
                      Modeling/CoOrdinateSystem.cpp
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
                      Editors/CompositeModelEditor.cpp
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
                      Annotations/ColorAnnotation.cpp
                      Annotations/ExtentAnnotation.cpp
                      Annotations/PointAnnotation.cpp
                      Annotations/RealAnnotation.cpp
                      Annotations/StringAnnotation.cpp
                      Element/ElementProperties.cpp
                      Element/Transformation.cpp
                      Modeling/DocumentationWidget.cpp
                      Simulation/TranslationFlagsWidget.cpp
                      Simulation/SimulationDialog.cpp
                      Simulation/SimulationOutputWidget.cpp
                      Simulation/SimulationOutputHandler.cpp
                      Simulation/OpcUaClient.cpp
                      Simulation/ArchivedSimulationsWidget.cpp
                      TLM/FetchInterfaceDataDialog.cpp
                      TLM/FetchInterfaceDataThread.cpp
                      TLM/TLMCoSimulationDialog.cpp
                      TLM/TLMCoSimulationOutputWidget.cpp
                      TLM/TLMCoSimulationThread.cpp
                      FMI/ImportFMUDialog.cpp
                      FMI/ImportFMUModelDescriptionDialog.cpp
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
                      Animation/OpenGLWidget.cpp
                      Animation/AbstractAnimationWindow.cpp
                      Animation/ViewerWidget.cpp
                      Animation/AnimationWindow.cpp
                      Animation/ThreeDViewer.cpp
                      Animation/ExtraShapes.cpp
                      Animation/Visualizer.cpp
                      Animation/VisualizerMAT.cpp
                      Animation/VisualizerCSV.cpp
                      Animation/VisualizerFMU.cpp
                      Animation/FMUSettingsDialog.cpp
                      Animation/FMUWrapper.cpp
                      Animation/Shapes.cpp
                      resource_omedit.qrc)


set(OMEDITLIB_HEADERS Util/Helper.h
                      Util/Utilities.h
                      Util/StringHandler.h
                      Util/OutputPlainTextEdit.h
                      MainWindow.h
                      OMC/OMCProxy.h
                      Modeling/MessagesWidget.h
                      Modeling/ItemDelegate.h
                      Modeling/LibraryTreeWidget.h
                      Modeling/Commands.h
                      Modeling/CoOrdinateSystem.h
                      Modeling/ModelWidgetContainer.h
                      Modeling/ModelicaClassDialog.h
                      Modeling/FunctionArgumentDialog.h
                      Modeling/InstallLibraryDialog.h
                      Search/SearchWidget.h
                      Options/OptionsDialog.h
                      Editors/BaseEditor.h
                      Editors/ModelicaEditor.h
                      Editors/TransformationsEditor.h
                      Editors/TextEditor.h
                      Editors/CEditor.h
                      Editors/CompositeModelEditor.h
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
                      Annotations/ColorAnnotation.h
                      Annotations/ExtentAnnotation.h
                      Annotations/PointAnnotation.h
                      Annotations/RealAnnotation.h
                      Annotations/StringAnnotation.h
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
                      TLM/FetchInterfaceDataDialog.h
                      TLM/FetchInterfaceDataThread.h
                      TLM/TLMCoSimulationOptions.h
                      TLM/TLMCoSimulationDialog.h
                      TLM/TLMCoSimulationOutputWidget.h
                      TLM/TLMCoSimulationThread.h
                      FMI/ImportFMUDialog.h
                      FMI/ImportFMUModelDescriptionDialog.h
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
                      Animation/OpenGLWidget.h
                      Animation/AbstractAnimationWindow.h
                      Animation/ViewerWidget.h
                      Animation/AnimationWindow.h
                      Animation/ThreeDViewer.h
                      Animation/AnimationUtil.h
                      Animation/ExtraShapes.h
                      Animation/Visualizer.h
                      Animation/VisualizerMAT.h
                      Animation/VisualizerCSV.h
                      Animation/VisualizerFMU.h
                      Animation/FMUSettingsDialog.h
                      Animation/FMUWrapper.h
                      Animation/Shapes.h
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

# qmake adds -DUNICODE by defult (As far as I can gather).
# So add it for CMake as well to avoid having to modify the code.
if(WIN32)
  target_compile_definitions(OMEditLib PRIVATE -DUNICODE)
endif()

target_link_libraries(OMEditLib PUBLIC omedit::config)
target_link_libraries(OMEditLib PUBLIC libOMSimulator)
target_link_libraries(OMEditLib PUBLIC OMParser)
target_link_libraries(OMEditLib PUBLIC omedit::debugger::parser)
target_link_libraries(OMEditLib PUBLIC Qt5::Xml)
target_link_libraries(OMEditLib PUBLIC Qt5::Widgets)
target_link_libraries(OMEditLib PUBLIC Qt5::PrintSupport)
target_link_libraries(OMEditLib PUBLIC Qt5::WebKitWidgets)
target_link_libraries(OMEditLib PUBLIC Qt5::OpenGL)
target_link_libraries(OMEditLib PUBLIC Qt5::Network)
target_link_libraries(OMEditLib PUBLIC Qt5::Svg)
target_link_libraries(OMEditLib PUBLIC Qt5::XmlPatterns)
target_link_libraries(OMEditLib PUBLIC omc::3rd::opcua)
target_link_libraries(OMEditLib PUBLIC OMPlotLib)
target_link_libraries(OMEditLib PUBLIC OpenModelicaCompiler)
target_link_libraries(OMEditLib PUBLIC ${OPENSCENEGRAPH_LIBRARIES})

if(MINGW)
  target_link_libraries(OMEditLib PUBLIC binutils::bfd)
  target_link_libraries(OMEditLib PUBLIC zlib)
endif()

target_include_directories(OMEditLib PRIVATE
  ${OMCompiler_SOURCE_DIR}/Compiler/Script)

target_link_options(OMEditLib PRIVATE -Wl,--no-undefined)

install(TARGETS OMEditLib)

