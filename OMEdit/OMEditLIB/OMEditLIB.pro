#
 # This file is part of OpenModelica.
 #
 # Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 # c/o Linköpings universitet, Department of Computer and Information Science,
 # SE-58183 Linköping, Sweden.
 #
 # All rights reserved.
 #
 # THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 # THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 # ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 # OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 #
 # The OpenModelica software and the Open Source Modelica
 # Consortium (OSMC) Public License (OSMC-PL) are obtained
 # from OSMC, either from the above address,
 # from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 # http://www.openmodelica.org, and in the OpenModelica distribution.
 # GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 #
 # This program is distributed WITHOUT ANY WARRANTY; without
 # even the implied warranty of  MERCHANTABILITY or FITNESS
 # FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 # IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 #
 # See the full OSMC Public License conditions for more details.
 #
 #/

include(../OMEdit.config.pre.pri)

DESTDIR = ../bin
ICON = Resources/icons/omedit.icns

TEMPLATE = lib
CONFIG += staticlib

TRANSLATIONS = Resources/nls/OMEdit_de.ts \
  Resources/nls/OMEdit_es.ts \
  Resources/nls/OMEdit_fr.ts \
  Resources/nls/OMEdit_it.ts \
  Resources/nls/OMEdit_ja.ts \
  Resources/nls/OMEdit_ro.ts \
  Resources/nls/OMEdit_ru.ts \
  Resources/nls/OMEdit_sv.ts \
  Resources/nls/OMEdit_zh_CN.ts

# This is very evil, lupdate just look for SOURCES variable and creates translations. This section is not compiled at all :)
evil_hack_to_fool_lupdate {
  SOURCES += ../../../OMPlot/OMPlotGUI/*.cpp
}

# Windows libraries and includes
win32 {

  CONFIG(release, debug|release) { # release
    # required for backtrace
    # In order to get the stack trace in Windows we must add -g flag. Qt automatically adds the -O2 flag for optimization.
    # We should also unset the QMAKE_LFLAGS_RELEASE define because it is defined as QMAKE_LFLAGS_RELEASE = -Wl,-s in qmake.conf file for MinGW
    # -s will remove all symbol table and relocation information from the executable.
    QMAKE_CXXFLAGS += -g -DUA_DYNAMIC_LINKING
    QMAKE_LFLAGS_RELEASE =
  }

  OPENMODELICAHOME = $$(OMBUILDDIR)
  host_short =

  CONFIG += osg
} else { # Unix libraries and includes
  include(OMEditLIB.unix.config.pri)
}

INCLUDEPATH += . ../ \
  $$OPENMODELICAHOME/include \
  $$OPENMODELICAHOME/include/omplot \
  $$OPENMODELICAHOME/include/omplot/qwt \
  $$OPENMODELICAHOME/include/$$host_short/omc/antlr3 \
  $$OPENMODELICAHOME/include/omc \
  $$OPENMODELICAHOME/include/omc/scripting-API \
  $$OPENMODELICAHOME/include/omc/c \
  $$OPENMODELICAHOME/include/omc/c/util \
  $$OPENMODELICAHOME/include/omc/fmil \
  $$OPENMODELICAHOME/../OMSimulator/include/ \
  $$OPENMODELICAHOME/../OMParser/ \
  $$OPENMODELICAHOME/../OMParser/3rdParty/antlr4/runtime/Cpp/runtime/src

contains(QMAKE_CXXFLAGS, -DOM_OMEDIT_ENABLE_LIBXML2) {
  INCLUDEPATH += $$(MSYSTEM_PREFIX)/include/libxml2
}

SOURCES += Util/Helper.cpp \
  Util/Utilities.cpp \
  Util/StringHandler.cpp \
  Util/OutputPlainTextEdit.cpp \
  Util/DirectoryOrFileSelector.cpp \
  MainWindow.cpp \
  $$OPENMODELICAHOME/include/omc/scripting-API/OpenModelicaScriptingAPIQt.cpp \
  OMC/OMCProxy.cpp \
  Modeling/Model.cpp \
  Modeling/MessagesWidget.cpp \
  Modeling/ItemDelegate.cpp \
  Modeling/LibraryTreeWidget.cpp \
  Modeling/ElementTreeWidget.cpp \
  Modeling/Commands.cpp \
  Modeling/ModelWidgetContainer.cpp \
  Modeling/ModelicaClassDialog.cpp \
  Modeling/FunctionArgumentDialog.cpp \
  Modeling/InstallLibraryDialog.cpp \
  Search/SearchWidget.cpp \
  Options/OptionsDialog.cpp \
  Editors/BaseEditor.cpp \
  Editors/ModelicaEditor.cpp \
  Editors/TransformationsEditor.cpp \
  Editors/TextEditor.cpp \
  Editors/CEditor.cpp \
  Editors/CRMLEditor.cpp \
  Editors/MOSEditor.cpp \
  Editors/OMSimulatorEditor.cpp \
  Editors/MetaModelicaEditor.cpp \
  Editors/HTMLEditor.cpp \
  Plotting/PlotWindowContainer.cpp \
  Element/Element.cpp \
  Annotations/ShapeAnnotation.cpp \
  Element/CornerItem.cpp \
  Annotations/LineAnnotation.cpp \
  Annotations/PolygonAnnotation.cpp \
  Annotations/RectangleAnnotation.cpp \
  Annotations/EllipseAnnotation.cpp \
  Annotations/TextAnnotation.cpp \
  Annotations/BitmapAnnotation.cpp \
  Annotations/DynamicAnnotation.cpp \
  Annotations/BooleanAnnotation.cpp \
  Annotations/PointAnnotation.cpp \
  Annotations/RealAnnotation.cpp \
  Annotations/ColorAnnotation.cpp \
  Annotations/LinePatternAnnotation.cpp \
  Annotations/FillPatternAnnotation.cpp \
  Annotations/PointArrayAnnotation.cpp \
  Annotations/ArrowAnnotation.cpp \
  Annotations/SmoothAnnotation.cpp \
  Annotations/ExtentAnnotation.cpp \
  Annotations/BorderPatternAnnotation.cpp \
  Annotations/EllipseClosureAnnotation.cpp \
  Annotations/StringAnnotation.cpp \
  Annotations/TextAlignmentAnnotation.cpp \
  Annotations/TextStyleAnnotation.cpp \
  Element/ElementProperties.cpp \
  Element/Transformation.cpp \
  Modeling/DocumentationWidget.cpp \
  Simulation/TranslationFlagsWidget.cpp \
  Simulation/SimulationDialog.cpp \
  Simulation/SimulationOutputWidget.cpp \
  Simulation/SimulationOutputHandler.cpp \
  Simulation/OpcUaClient.cpp \
  Simulation/ArchivedSimulationsWidget.cpp \
  FMI/ImportFMUDialog.cpp \
  FMI/ImportFMUModelDescriptionDialog.cpp \
  FMI/FMUExportOutputWidget.cpp \
  Plotting/VariablesWidget.cpp \
  Plotting/DiagramWindow.cpp \
  Options/NotificationsDialog.cpp \
  Annotations/ShapePropertiesDialog.cpp \
  TransformationalDebugger/OMDumpXML.cpp \
  TransformationalDebugger/diff_match_patch.cpp \
  TransformationalDebugger/TransformationsWidget.cpp \
  Debugger/GDB/CommandFactory.cpp \
  Debugger/GDB/GDBAdapter.cpp \
  Debugger/StackFrames/StackFramesWidget.cpp \
  Debugger/Locals/LocalsWidget.cpp \
  Debugger/Locals/ModelicaValue.cpp \
  Debugger/Breakpoints/BreakpointMarker.cpp \
  Debugger/Breakpoints/BreakpointsWidget.cpp \
  Debugger/Breakpoints/BreakpointDialog.cpp \
  Debugger/DebuggerConfigurationsDialog.cpp \
  Debugger/Attach/AttachToProcessDialog.cpp \
  Debugger/Attach/ProcessListModel.cpp \
  CrashReport/backtrace.c \
  CrashReport/GDBBacktrace.cpp \
  CrashReport/CrashReportDialog.cpp \
  CRML/CRMLTranslateAsDialog.cpp \
  CRML/CRMLTranslatorOutputWidget.cpp \
  Git/GitCommands.cpp \
  Git/CommitChangesDialog.cpp \
  Git/RevertCommitsDialog.cpp \
  Git/CleanDialog.cpp \
  OMEditApplication.cpp \
  Traceability/TraceabilityGraphViewWidget.cpp \
  Traceability/TraceabilityInformationURI.cpp \
  OMS/OMSProxy.cpp \
  OMS/ModelDialog.cpp \
  OMS/BusDialog.cpp \
  OMS/ElementPropertiesDialog.cpp \
  OMS/SystemSimulationInformationDialog.cpp \
  OMS/OMSSimulationDialog.cpp \
  OMS/OMSSimulationOutputWidget.cpp \
  Animation/TimeManager.cpp \
  Util/ResourceCache.cpp \
  Util/NetworkAccessManager.cpp \
  Util/GitHubArtifactDownloader.cpp \
  FlatModelica/Expression.cpp \
  FlatModelica/ExpressionFuncs.cpp \
  FlatModelica/Parser.cpp

HEADERS  += Util/Helper.h \
  Util/Utilities.h \
  Util/StringHandler.h \
  Util/OutputPlainTextEdit.h \
  Util/DirectoryOrFileSelector.h \
  MainWindow.h \
  $$OPENMODELICAHOME/include/omc/scripting-API/OpenModelicaScriptingAPIQt.h \
  OMC/OMCProxy.h \
  Modeling/Model.h \
  Modeling/MessagesWidget.h \
  Modeling/ItemDelegate.h \
  Modeling/LibraryTreeWidget.h \
  Modeling/ElementTreeWidget.h \
  Modeling/Commands.h \
  Modeling/ModelWidgetContainer.h \
  Modeling/ModelicaClassDialog.h \
  Modeling/FunctionArgumentDialog.h \
  Modeling/InstallLibraryDialog.h \
  Search/SearchWidget.h \
  Options/OptionsDefaults.h \
  Options/OptionsDialog.h \
  Editors/BaseEditor.h \
  Editors/ModelicaEditor.h \
  Editors/TransformationsEditor.h \
  Editors/TextEditor.h \
  Editors/CEditor.h \
  Editors/CRMLEditor.h \
  Editors/MOSEditor.h \
  Editors/OMSimulatorEditor.h \
  Editors/MetaModelicaEditor.h \
  Editors/HTMLEditor.h \
  Plotting/PlotWindowContainer.h \
  Element/Element.h \
  Annotations/ShapeAnnotation.h \
  Element/CornerItem.h \
  Annotations/LineAnnotation.h \
  Annotations/PolygonAnnotation.h \
  Annotations/RectangleAnnotation.h \
  Annotations/EllipseAnnotation.h \
  Annotations/TextAnnotation.h \
  Annotations/BitmapAnnotation.h \
  Annotations/DynamicAnnotation.h \
  Annotations/BooleanAnnotation.h \
  Annotations/PointAnnotation.h \
  Annotations/RealAnnotation.h \
  Annotations/ColorAnnotation.h \
  Annotations/LinePatternAnnotation.h \
  Annotations/FillPatternAnnotation.h \
  Annotations/PointArrayAnnotation.h \
  Annotations/ArrowAnnotation.h \
  Annotations/SmoothAnnotation.h \
  Annotations/ExtentAnnotation.h \
  Annotations/BorderPatternAnnotation.h \
  Annotations/EllipseClosureAnnotation.h \
  Annotations/StringAnnotation.h \
  Annotations/TextAlignmentAnnotation.h \
  Annotations/TextStyleAnnotation.h \
  Element/ElementProperties.h \
  Element/Transformation.h \
  Modeling/DocumentationWidget.h \
  Simulation/SimulationOptions.h \
  Simulation/TranslationFlagsWidget.h \
  Simulation/SimulationDialog.h \
  Simulation/SimulationOutputWidget.h \
  Simulation/SimulationOutputHandler.h \
  Simulation/OpcUaClient.h \
  Simulation/ArchivedSimulationsWidget.h \
  FMI/ImportFMUDialog.h \
  FMI/ImportFMUModelDescriptionDialog.h \
  FMI/FMUExportOutputWidget.h \
  Plotting/VariablesWidget.h \
  Plotting/DiagramWindow.h \
  Options/NotificationsDialog.h \
  Annotations/ShapePropertiesDialog.h \
  TransformationalDebugger/OMDumpXML.cpp \
  TransformationalDebugger/diff_match_patch.h \
  TransformationalDebugger/TransformationsWidget.h \
  Debugger/GDB/CommandFactory.h \
  Debugger/GDB/GDBAdapter.h \
  Debugger/StackFrames/StackFramesWidget.h \
  Debugger/Locals/LocalsWidget.h \
  Debugger/Locals/ModelicaValue.h \
  Debugger/Breakpoints/BreakpointMarker.h \
  Debugger/Breakpoints/BreakpointsWidget.h \
  Debugger/Breakpoints/BreakpointDialog.h \
  Debugger/DebuggerConfigurationsDialog.h \
  Debugger/Attach/AttachToProcessDialog.h \
  Debugger/Attach/ProcessListModel.h \
  CrashReport/backtrace.h \
  CrashReport/GDBBacktrace.h \
  CrashReport/CrashReportDialog.h \
  CRML/CRMLTranslateAsDialog.h \
  CRML/CRMLTranslatorOptions.h \
  CRML/CRMLTranslatorOutputWidget.h \
  Git/GitCommands.h \
  Git/CommitChangesDialog.h \
  Git/RevertCommitsDialog.h \
  Git/CleanDialog.h \
  OMEditApplication.h \
  Traceability/TraceabilityGraphViewWidget.h \
  Traceability/TraceabilityInformationURI.h \
  OMS/OMSProxy.h \
  OMS/ModelDialog.h \
  OMS/BusDialog.h \
  OMS/ElementPropertiesDialog.h \
  OMS/SystemSimulationInformationDialog.h \
  OMS/OMSSimulationDialog.h \
  OMS/OMSSimulationOutputWidget.h \
  Animation/TimeManager.h \
  Interfaces/InformationInterface.h \
  Interfaces/ModelInterface.h \
  Util/ResourceCache.h \
  Util/NetworkAccessManager.h \
  Util/GitHubArtifactDownloader.h \
  FlatModelica/Expression.h \
  FlatModelica/ExpressionFuncs.h \
  FlatModelica/Parser.h

CONFIG(osg) {

  greaterThan(QT_MAJOR_VERSION, 4):greaterThan(QT_MINOR_VERSION, 3) { # if Qt 5.4 or greater
    SOURCES += Animation/OpenGLWidget.cpp
  } else {
    SOURCES += Animation/GLWidget.cpp
  }
  SOURCES += Animation/AbstractAnimationWindow.cpp \
    Animation/ViewerWidget.cpp \
    Animation/AnimationWindow.cpp \
    Animation/ThreeDViewer.cpp \
    Animation/ExtraShapes.cpp \
    Animation/Visualization.cpp \
    Animation/VisualizationMAT.cpp \
    Animation/VisualizationCSV.cpp \
    Animation/VisualizationFMU.cpp \
    Animation/FMUSettingsDialog.cpp \
    Animation/FMUWrapper.cpp \
    Animation/AbstractVisualizer.cpp \
    Animation/Shape.cpp \
    Animation/Vector.cpp

  greaterThan(QT_MAJOR_VERSION, 4):greaterThan(QT_MINOR_VERSION, 3) { # if Qt 5.4 or greater
    HEADERS += Animation/OpenGLWidget.h
  } else {
    HEADERS += Animation/GLWidget.h
  }
  HEADERS += Animation/AbstractAnimationWindow.h \
    Animation/ViewerWidget.h \
    Animation/AnimationWindow.h \
    Animation/AnimationUtil.h \
    Animation/ExtraShapes.h \
    Animation/Visualization.h \
    Animation/VisualizationMAT.h \
    Animation/VisualizationCSV.h \
    Animation/VisualizationFMU.h \
    Animation/FMUSettingsDialog.h \
    Animation/FMUWrapper.h \
    Animation/AbstractVisualizer.h \
    Animation/Shape.h \
    Animation/Vector.h \
    Animation/rapidxml.hpp
}

OTHER_FILES += Resources/css/stylesheet.qss \
  Debugger/Parser/GDBMIOutput.g \
  Debugger/Parser/GDBMIParser.h \
  Debugger/Parser/GDBMIParser.cpp \
  Debugger/Parser/main.cpp

RESOURCES += resource_omedit.qrc

include(../OMEdit.config.post.pri)
