/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */
/*
 * @author Adeel Asghar <adeel.asghar@liu.se>
 */

#ifndef HELPER_H
#define HELPER_H

#include <stdlib.h>
#include <QString>
#include <QSize>
#include <QObject>
#include <QFontInfo>

class Helper : public QObject
{
  Q_OBJECT
public:
  static void initHelperVariables();
  /* Global non-translated variables */
  static QString applicationName;
  static QString applicationIntroText;
  static QString organization;
  static QString application;
  static QString OpenModelicaVersion;
  static QString OpenModelicaHome;
  static QString OpenModelicaLibrary;
  static QString OMCServerName;
  static QString omFileTypes;
  static QString omEncryptedFileTypes;
  static QString omnotebookFileTypes;
  static QString ngspiceNetlistFileTypes;
  static QString imageFileTypes;
  static QString bitmapFileTypes;
  static QString fmuFileTypes;
  static QString xmlFileTypes;
  static QString infoXmlFileTypes;
  static QString matFileTypes;
  static QString csvFileTypes;
  static QString omResultFileTypes;
  static QString exeFileTypes;
  static QString txtFileTypes;
  static QString figaroFileTypes;
  static QString visualizationFileTypes;
  static QString omsFileTypes;
  static QString subModelFileTypes;
  static int treeIndentation;
  static QSize iconSize;
  static int tabWidth;
  static QString modelicaComponentFormat;
  static QString modelicaFileFormat;
  static QString busConnectorFormat;
  static qreal shapesStrokeWidth;
  static int headingFontSize;
  static QString ModelicaSimulationOutputFormats;
  static QString clockOptions;
  static QString notificationLevel;
  static QString warningLevel;
  static QString errorLevel;
  static QString syntaxKind;
  static QString grammarKind;
  static QString translationKind;
  static QString symbolicKind;
  static QString simulationKind;
  static QString scriptingKind;
  static QString tabbed;
  static QString subWindow;
  static QString structuredOutput;
  static QString textOutput;
  static QString utf8;
  static const char * const fmuPlatformNamePropertyId;
  static QFontInfo systemFontInfo;
  static QFontInfo monospacedFontInfo;
  static QString toolsOptionsPath;
  static QString speedOptions;
  /* Meta Modelica Types */
  static QString MODELICA_METATYPE;
  static QString MODELICA_STRING;
  static QString MODELICA_BOOLEAN;
  static QString MODELICA_INETGER;
  static QString MODELICA_REAL;
  static QString REPLACEABLE_TYPE_ANY;
  static QString RECORD;
  static QString LIST;
  static QString OPTION;
  static QString TUPLE;
  static QString ARRAY;
  static QString VALUE_OPTIMIZED_OUT;
  /* Modelica Types */
  static QString STRING;
  static QString BOOLEAN;
  static QString INTEGER;
  static QString REAL;
  /* OMSimulator system types */
  static QString systemTLM;
  static QString systemWC;
  static QString systemSC;
  /* Global translated variables */
  static QString newModelicaClass;
  static QString createNewModelicaClass;
  static QString openModelicaFiles;
  static QString openConvertModelicaFiles;
  static QString libraries;
  static QString clearRecentFiles;
  static QString encoding;
  static QString fileLabel;
  static QString file;
  static QString folder;
  static QString browse;
  static QString ok;
  static QString cancel;
  static QString reset;
  static QString close;
  static QString error;
  static QString chooseFile;
  static QString chooseFiles;
  static QString attributes;
  static QString properties;
  static QString add;
  static QString edit;
  static QString save;
  static QString saveTip;
  static QString saveAs;
  static QString saveAsTip;
  static QString saveTotal;
  static QString saveTotalTip;
  static QString apply;
  static QString chooseDirectory;
  static QString general;
  static QString output;
  static QString parameters;
  static QString inputs;
  static QString name;
  static QString comment;
  static QString path;
  static QString type;
  static QString information;
  static QString rename;
  static QString renameTip;
  static QString OMSRenameTip;
  static QString checkModel;
  static QString checkModelTip;
  static QString checkAllModels;
  static QString checkAllModelsTip;
  static QString instantiateModel;
  static QString instantiateModelTip;
  static QString FMU;
  static QString exportFMUTip;
  static QString exportReadonlyPackage;
  static QString exportRealonlyPackageTip;
  static QString exportEncryptedPackage;
  static QString exportEncryptedPackageTip;
  static QString importFMU;
  static QString importFMUTip;
  static QString exportXML;
  static QString exportXMLTip;
  static QString exportToOMNotebook;
  static QString exportToOMNotebookTip;
  static QString importFromOMNotebook;
  static QString importNgspiceNetlist;
  static QString importFromOMNotebookTip;
  static QString importNgspiceNetlistTip;
  static QString line;
  static QString exportAsImage;
  static QString exportAsImageTip;
  static QString exportFigaro;
  static QString exportFigaroTip;
  static QString OpenModelicaCompilerCLI;
  static QString deleteStr;
  static QString copy;
  static QString paste;
  static QString resetZoom;
  static QString zoomIn;
  static QString zoomOut;
  static QString loading;
  static QString question;
  static QString search;
  static QString duplicate;
  static QString duplicateTip;
  static QString unloadClass;
  static QString unloadClassTip;
  static QString unloadCompositeModelOrTextTip;
  static QString unloadOMSModelTip;
  static QString refresh;
  static QString simulate;
  static QString simulateTip;
  static QString callFunction;
  static QString callFunctionTip;
  static QString reSimulate;
  static QString reSimulateTip;
  static QString reSimulateSetup;
  static QString reSimulateSetupTip;
  static QString exportVariables;
  static QString simulateWithTransformationalDebugger;
  static QString simulateWithTransformationalDebuggerTip;
  static QString simulateWithAlgorithmicDebugger;
  static QString simulateWithAlgorithmicDebuggerTip;
  static QString simulateWithAnimation;
  static QString simulateWithAnimationTip;
  static QString simulationSetup;
  static QString simulationSetupTip;
  static QString simulation;
  static QString reSimulation;
  static QString interactiveSimulation;
  static QString options;
  static QString extent;
  static QString bottom;
  static QString top;
  static QString grid;
  static QString horizontal;
  static QString vertical;
  static QString component;
  static QString scaleFactor;
  static QString preserveAspectRatio;
  static QString originX;
  static QString originY;
  static QString rotation;
  static QString thickness;
  static QString smooth;
  static QString bezier;
  static QString startArrow;
  static QString endArrow;
  static QString arrowSize;
  static QString size;
  static QString lineStyle;
  static QString color;
  static QString Colors;
  static QString fontFamily;
  static QString fontSize;
  static QString pickColor;
  static QString pattern;
  static QString fillStyle;
  static QString extent1X;
  static QString extent1Y;
  static QString extent2X;
  static QString extent2Y;
  static QString radius;
  static QString startAngle;
  static QString endAngle;
  static QString curveStyle;
  static QString figaro;
  static QString remove;
  static QString errorLocation;
  static QString fileLocation;
  static QString readOnly;
  static QString writable;
  static QString workingDirectory;
  static QString iconView;
  static QString diagramView;
  static QString textView;
  static QString documentationView;
  static QString filterClasses;
  static QString findReplaceModelicaText;
  static QString left;
  static QString center;
  static QString right;
  static QString createConnection;
  static QString connectionAttributes;
  static QString createTransition;
  static QString editTransition;
  static QString findVariables;
  static QString filterVariables;
  static QString openClass;
  static QString openClassTip;
  static QString viewIcon;
  static QString viewIconTip;
  static QString viewDiagram;
  static QString viewDiagramTip;
  static QString viewText;
  static QString viewTextTip;
  static QString viewDocumentation;
  static QString viewDocumentationTip;
  static QString dontShowThisMessageAgain;
  static QString clickAndDragToResize;
  static QString variables;
  static QString variablesBrowser;
  static QString description;
  static QString previous;
  static QString next;
  static QString reload;
  static QString index;
  static QString equation;
  static QString transformationalDebugger;
  static QString executionCount;
  static QString executionMaxTime;
  static QString executionTime;
  static QString executionFraction;
  static QString debuggingFileNotSaveInfo;
  static QString algorithmicDebugger;
  static QString debugConfigurations;
  static QString debugConfigurationsTip;
  static QString createGitReposiory;
  static QString createGitReposioryTip;
  static QString logCurrentFile;
  static QString logCurrentFileTip;
  static QString stageCurrentFileForCommit;
  static QString stageCurrentFileForCommitTip;
  static QString unstageCurrentFileFromCommit;
  static QString unstageCurrentFileFromCommitTip;
  static QString commitFiles;
  static QString commitFilesTip;
  static QString resume;
  static QString interrupt;
  static QString exit;
  static QString stepOver;
  static QString stepInto;
  static QString stepReturn;
  static QString attachToRunningProcess;
  static QString attachToRunningProcessTip;
  static QString crashReport;
  static QString parsingFailedJson;
  static QString expandAll;
  static QString collapseAll;
  static QString version;
  static QString unlimited;
  static QString simulationOutput;
  static QString cancelSimulation;
  static QString fetchInterfaceData;
  static QString fetchInterfaceDataTip;
  static QString alignInterfaces;
  static QString alignInterfacesTip;
  static QString tlmCoSimulationSetup;
  static QString tlmCoSimulationSetupTip;
  static QString tlmCoSimulation;
  static QString animationChooseFile;
  static QString animationChooseFileTip;
  static QString animationInitialize;
  static QString animationInitializeTip;
  static QString animationPlay;
  static QString animationPlayTip;
  static QString animationPause;
  static QString animationPauseTip;
  static QString simulationParams;
  static QString simulationParamsTip;
  static QString newModel;
  static QString addSystem;
  static QString addSystemTip;
  static QString addSubModel;
  static QString addSubModelTip;
  static QString addBus;
  static QString addBusTip;
  static QString editBus;
  static QString addTLMBus;
  static QString addTLMBusTip;
  static QString editTLMBus;
  static QString addConnector;
  static QString addConnectorTip;
  static QString addBusConnection;
  static QString editBusConnection;
  static QString addTLMConnection;
  static QString editTLMConnection;
  static QString running;
  static QString finished;
  static QString newVariable;
  static QString library;
  static QString moveUp;
  static QString moveDown;
  static QString fixErrorsManually;
  static QString revertToLastCorrectVersion;
  static QString translationFlagsTip;
  static QString saveExperimentAnnotation;
  static QString saveOpenModelicaSimulationFlagsAnnotation;
  static QString saveOpenModelicaCommandLineOptionsAnnotation;
  static QString item;
  static QString bold;
  static QString italic;
  static QString underline;
  static QString condition;
  static QString immediate;
  static QString synchronize;
  static QString priority;
  static QString secs;
  static QString saveContentsInOneFile;
  static QString OMSSimulateTip;
  static QString dateTime;
  static QString startTime;
  static QString stopTime;
  static QString status;
  static QString speed;
  static QString instantiateOMSModelTip;
  static QString terminateInstantiation;
  static QString terminateInstantiationTip;
  static QString archivedSimulations;
  static QString systemSimulationInformation;
  static QString translationFlags;
};

class GUIMessages : public QObject
{
  Q_OBJECT
public:
  enum MessagesTypes {
    CHECK_MESSAGES_BROWSER,
    SAME_COMPONENT_NAME,
    SAME_COMPONENT_CONNECT,
    NO_MODELICA_CLASS_OPEN,
    SIMULATION_STARTTIME_LESSTHAN_STOPTIME,
    ENTER_NAME,
    EXTENDS_CLASS_NOT_FOUND,
    INSERT_IN_CLASS_NOT_FOUND,
    INSERT_IN_SYSTEM_LIBRARY_NOT_ALLOWED,
    MODEL_ALREADY_EXISTS,
    ITEM_ALREADY_EXISTS,
    OPENMODELICAHOME_NOT_FOUND,
    ERROR_OCCURRED,
    ERROR_IN_TEXT,
    REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY,
    NO_OPENMODELICA_KEYWORDS,
    UNABLE_TO_LOAD_FILE,
    UNABLE_TO_OPEN_FILE,
    UNABLE_TO_SAVE_FILE,
    UNABLE_TO_DELETE_FILE,
    FILE_NOT_FOUND,
    ERROR_OPENING_FILE,
    UNABLE_TO_LOAD_MODEL,
    DELETE_AND_LOAD,
    REDEFINING_EXISTING_CLASSES,
    MULTIPLE_TOP_LEVEL_CLASSES,
    DIAGRAM_VIEW_DROP_MSG,
    ICON_VIEW_DROP_MSG,
    PLOT_PARAMETRIC_DIFF_FILES,
    ENTER_VALID_NUMBER,
    ENTER_VALUE,
    ITEM_DROPPED_ON_ITSELF,
    MAKE_REPLACEABLE_IF_PARTIAL,
    INNER_MODEL_NAME_CHANGED,
    FMU_GENERATED,
    FMU_MOVE_FAILED,
    FMU_EMPTY_PLATFORMS,
    XML_GENERATED,
    FIGARO_GENERATED,
    ENCRYPTED_PACKAGE_GENERATED,
    READONLY_PACKAGE_GENERATED,
    UNLOAD_CLASS_MSG,
    DELETE_CLASS_MSG,
    UNLOAD_TEXT_FILE_MSG,
    DELETE_TEXT_FILE_MSG,
    WRONG_MODIFIER,
    SET_INFO_XML_FLAG,
    DEBUG_CONFIGURATION_EXISTS_MSG,
    DEBUG_CONFIGURATION_SIZE_EXCEED,
    DELETE_DEBUG_CONFIGURATION_MSG,
    DEBUGGER_ALREADY_RUNNING,
    CLASS_NOT_FOUND,
    BREAKPOINT_INSERT_NOT_SAVED,
    BREAKPOINT_INSERT_NOT_MODELICA_CLASS,
    TLMMANAGER_NOT_SET,
    COMPOSITEMODEL_UNSAVED,
    TLMCOSIMULATION_ALREADY_RUNNING,
    TERMINAL_COMMAND_NOT_SET,
    UNABLE_FIND_COMPONENT_IN_CONNECTION,
    UNABLE_FIND_COMPONENT_IN_TRANSITION,
    UNABLE_FIND_COMPONENT_IN_INITIALSTATE,
    SELECT_SIMULATION_OPTION,
    INVALID_TRANSITION_CONDITION,
    MULTIPLE_DECLARATIONS_COMPONENT,
    GDB_ERROR,
    INVALID_INSTANCE_NAME
  };

  static QString getMessage(int type);
};

#endif // HELPER_H
