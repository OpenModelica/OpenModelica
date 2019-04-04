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

#include "Helper.h"
#include <QDir>

/* Global non-translated variables */
QString Helper::applicationName = "OMEdit";
QString Helper::applicationIntroText = "OpenModelica Connection Editor";
QString Helper::organization = "openmodelica";  /* case-sensitive string. Don't change it. Used by ini settings file. */
QString Helper::application = "omedit"; /* case-sensitive string. Don't change it. Used by ini settings file. */
// these two variables are set once we are connected to OMC......in OMCProxy::startServer().
QString Helper::OpenModelicaVersion = "";
QString Helper::OpenModelicaHome = "";
QString Helper::OpenModelicaLibrary = "";
QString Helper::OMCServerName = "OMEdit";
QString Helper::omFileTypes = "All Modelica Files (*.mo *.mol);;Modelica Files (*.mo);;Encrypted Modelica Libraries (*.mol)";
QString Helper::omEncryptedFileTypes = "Encrypted Modelica Libraries (*.mol)";
QString Helper::omnotebookFileTypes = "OMNotebook Files (*.onb *.onbz *.nb)";
QString Helper::ngspiceNetlistFileTypes = "ngspice Netlist Files (*.cir *.sp *.spice)";
QString Helper::imageFileTypes = "SVG (*.svg);;PNG image (*.png);;Windows BMP image (*.bmp);;TIFF (*.tiff)";
QString Helper::bitmapFileTypes = "Image Files (*.png *.bmp *.jpg *.jpeg);;PNG image (*.png);;Windows BMP image (*.bmp);;JPEG (*.jpg *.jpeg)";
QString Helper::fmuFileTypes = "FMU Files (*.fmu)";
QString Helper::xmlFileTypes = "XML Files (*.xml)";
QString Helper::infoXmlFileTypes = "OM Info Files (*_info.json)";
QString Helper::matFileTypes = "MAT Files (*.mat)";
QString Helper::csvFileTypes = "CSV Files (*.csv)";
QString Helper::omResultFileTypes = "OpenModelica Result Files (*.mat *.plt *.csv)";
#ifdef WIN32
QString Helper::exeFileTypes = "EXE Files (*.exe)";
#else
QString Helper::exeFileTypes = "Executable files (*)";
#endif
QString Helper::txtFileTypes = "TXT Files (*.txt)";
QString Helper::figaroFileTypes = "Figaro Files (*.fi)";
QString Helper::visualizationFileTypes = "Visualization Files (*.mat *.csv *.fmu);;Visualization MAT(*.mat);;Visualization CSV(*.csv);;Visualization FMU(*.fmu)";
QString Helper::omsFileTypes = "Composite Model Files (*.ssp)";
QString Helper::subModelFileTypes = "SubModel Files (*.fmu *.mat *.csv);;SubModel FMU (*.fmu);;SubModel MAT (*.mat);;SubModel CSV (*.csv)";
int Helper::treeIndentation = 13;
QSize Helper::iconSize = QSize(20, 20);
int Helper::tabWidth = 20;
QString Helper::modelicaComponentFormat = "image/modelica-component";
QString Helper::modelicaFileFormat = "text/uri-list";
QString Helper::busConnectorFormat = "bus/connector";
qreal Helper::shapesStrokeWidth = 2.0;
int Helper::headingFontSize = 18;
QString Helper::ModelicaSimulationOutputFormats = "mat,plt,csv";
QString Helper::clockOptions = ",RT,CYC,CPU";
QString Helper::notificationLevel = ".OpenModelica.Scripting.ErrorLevel.notification";
QString Helper::warningLevel = ".OpenModelica.Scripting.ErrorLevel.warning";
QString Helper::errorLevel = ".OpenModelica.Scripting.ErrorLevel.error";
QString Helper::syntaxKind = ".OpenModelica.Scripting.ErrorKind.syntax";
QString Helper::grammarKind = ".OpenModelica.Scripting.ErrorKind.grammar";
QString Helper::translationKind = ".OpenModelica.Scripting.ErrorKind.translation";
QString Helper::symbolicKind = ".OpenModelica.Scripting.ErrorKind.symbolic";
QString Helper::simulationKind = ".OpenModelica.Scripting.ErrorKind.simulation";
QString Helper::scriptingKind = ".OpenModelica.Scripting.ErrorKind.scripting";
QString Helper::tabbed = "Tabbed";
QString Helper::subWindow = "SubWindow";
QString Helper::structuredOutput = "Structured";
QString Helper::textOutput = "Text";
QString Helper::utf8 = "UTF-8";
const char * const Helper::fmuPlatformNamePropertyId = "fmu-platform-name";
QFontInfo Helper::systemFontInfo = QFontInfo(QFont());
QFontInfo Helper::monospacedFontInfo = QFontInfo(QFont());
#ifdef Q_OS_MAC
QString Helper::toolsOptionsPath = "OMEdit->Preferences";
#else
QString Helper::toolsOptionsPath = "Tools->Options";
#endif
QString Helper::speedOptions = "10,5,2,1,0.5,0.2,0.1";
/* Meta Modelica Types */
QString Helper::MODELICA_METATYPE = QString("modelica_metatype");
QString Helper::MODELICA_STRING = QString("modelica_string");
QString Helper::MODELICA_BOOLEAN = QString("modelica_boolean");
QString Helper::MODELICA_INETGER = QString("modelica_integer");
QString Helper::MODELICA_REAL = QString("modelica_real");
QString Helper::REPLACEABLE_TYPE_ANY = QString("replaceable type Any");
QString Helper::RECORD = QString("record");
QString Helper::LIST = QString("list");
QString Helper::OPTION = QString("Option");
QString Helper::TUPLE = QString("tuple");
QString Helper::ARRAY = QString("Array");
QString Helper::VALUE_OPTIMIZED_OUT = QString("value has been optimized out");
/* Modelica Types */
QString Helper::STRING = QString("String");
QString Helper::BOOLEAN = QString("Boolean");
QString Helper::INTEGER = QString("Integer");
QString Helper::REAL = QString("Real");
/* OMSimulator system types */
QString Helper::systemTLM = QString("TLM - Transmission Line Modeling System");
QString Helper::systemWC = QString("Weakly Coupled - Connected Co-Simulation FMUs System");
QString Helper::systemSC = QString("Strongly Coupled - Connected Model-Exchange FMUs System");
/* Global translated variables */
QString Helper::newModelicaClass;
QString Helper::createNewModelicaClass;
QString Helper::openModelicaFiles;
QString Helper::openConvertModelicaFiles;
QString Helper::libraries;
QString Helper::clearRecentFiles;
QString Helper::encoding;
QString Helper::fileLabel;
QString Helper::file;
QString Helper::folder;
QString Helper::browse;
QString Helper::ok;
QString Helper::cancel;
QString Helper::reset;
QString Helper::close;
QString Helper::error;
QString Helper::chooseFile;
QString Helper::chooseFiles;
QString Helper::attributes;
QString Helper::properties;
QString Helper::add;
QString Helper::edit;
QString Helper::save;
QString Helper::saveTip;
QString Helper::saveAs;
QString Helper::saveAsTip;
QString Helper::saveTotal;
QString Helper::saveTotalTip;
QString Helper::apply;
QString Helper::chooseDirectory;
QString Helper::general;
QString Helper::output;
QString Helper::parameters;
QString Helper::inputs;
QString Helper::name;
QString Helper::comment;
QString Helper::path;
QString Helper::type;
QString Helper::information;
QString Helper::rename;
QString Helper::renameTip;
QString Helper::OMSRenameTip;
QString Helper::checkModel;
QString Helper::checkModelTip;
QString Helper::checkAllModels;
QString Helper::checkAllModelsTip;
QString Helper::instantiateModel;
QString Helper::instantiateModelTip;
QString Helper::FMU;
QString Helper::exportFMUTip;
QString Helper::exportEncryptedPackage;
QString Helper::exportEncryptedPackageTip;
QString Helper::exportReadonlyPackage;
QString Helper::exportRealonlyPackageTip;
QString Helper::importFMU;
QString Helper::importFMUTip;
QString Helper::exportXML;
QString Helper::exportXMLTip;
QString Helper::exportToOMNotebook;
QString Helper::exportToOMNotebookTip;
QString Helper::importFromOMNotebook;
QString Helper::importNgspiceNetlist;
QString Helper::importFromOMNotebookTip;
QString Helper::importNgspiceNetlistTip;
QString Helper::line;
QString Helper::exportAsImage;
QString Helper::exportAsImageTip;
QString Helper::exportFigaro;
QString Helper::exportFigaroTip;
QString Helper::OpenModelicaCompilerCLI;
QString Helper::deleteStr;
QString Helper::copy;
QString Helper::paste;
QString Helper::resetZoom;
QString Helper::zoomIn;
QString Helper::zoomOut;
QString Helper::loading;
QString Helper::question;
QString Helper::search;
QString Helper::unloadClass;
QString Helper::duplicate;
QString Helper::duplicateTip;
QString Helper::unloadClassTip;
QString Helper::unloadCompositeModelOrTextTip;
QString Helper::unloadOMSModelTip;
QString Helper::refresh;
QString Helper::simulate;
QString Helper::simulateTip;
QString Helper::callFunction;
QString Helper::callFunctionTip;
QString Helper::reSimulate;
QString Helper::reSimulateTip;
QString Helper::reSimulateSetup;
QString Helper::reSimulateSetupTip;
QString Helper::exportVariables;
QString Helper::simulateWithTransformationalDebugger;
QString Helper::simulateWithTransformationalDebuggerTip;
QString Helper::simulateWithAlgorithmicDebugger;
QString Helper::simulateWithAlgorithmicDebuggerTip;
QString Helper::simulateWithAnimation;
QString Helper::simulateWithAnimationTip;
QString Helper::simulationSetup;
QString Helper::simulationSetupTip;
QString Helper::simulation;
QString Helper::reSimulation;
QString Helper::interactiveSimulation;
QString Helper::options;
QString Helper::extent;
QString Helper::bottom;
QString Helper::top;
QString Helper::grid;
QString Helper::horizontal;
QString Helper::vertical;
QString Helper::component;
QString Helper::scaleFactor;
QString Helper::preserveAspectRatio;
QString Helper::originX;
QString Helper::originY;
QString Helper::rotation;
QString Helper::thickness;
QString Helper::smooth;
QString Helper::bezier;
QString Helper::startArrow;
QString Helper::endArrow;
QString Helper::arrowSize;
QString Helper::size;
QString Helper::lineStyle;
QString Helper::color;
QString Helper::Colors;
QString Helper::fontFamily;
QString Helper::fontSize;
QString Helper::pickColor;
QString Helper::pattern;
QString Helper::fillStyle;
QString Helper::extent1X;
QString Helper::extent1Y;
QString Helper::extent2X;
QString Helper::extent2Y;
QString Helper::radius;
QString Helper::startAngle;
QString Helper::endAngle;
QString Helper::curveStyle;
QString Helper::figaro;
QString Helper::remove;
QString Helper::fileLocation;
QString Helper::errorLocation;
QString Helper::readOnly;
QString Helper::writable;
QString Helper::workingDirectory;
QString Helper::iconView;
QString Helper::diagramView;
QString Helper::textView;
QString Helper::documentationView;
QString Helper::filterClasses;
QString Helper::findReplaceModelicaText;
QString Helper::left;
QString Helper::center;
QString Helper::right;
QString Helper::createConnection;
QString Helper::connectionAttributes;
QString Helper::createTransition;
QString Helper::editTransition;
QString Helper::findVariables;
QString Helper::filterVariables;
QString Helper::openClass;
QString Helper::openClassTip;
QString Helper::viewIcon;
QString Helper::viewIconTip;
QString Helper::viewDiagram;
QString Helper::viewDiagramTip;
QString Helper::viewText;
QString Helper::viewTextTip;
QString Helper::viewDocumentation;
QString Helper::viewDocumentationTip;
QString Helper::dontShowThisMessageAgain;
QString Helper::clickAndDragToResize;
QString Helper::variables;
QString Helper::variablesBrowser;
QString Helper::description;
QString Helper::previous;
QString Helper::next;
QString Helper::reload;
QString Helper::index;
QString Helper::equation;
QString Helper::transformationalDebugger;
QString Helper::executionCount;
QString Helper::executionMaxTime;
QString Helper::executionTime;
QString Helper::executionFraction;
QString Helper::debuggingFileNotSaveInfo;
QString Helper::algorithmicDebugger;
QString Helper::debugConfigurations;
QString Helper::debugConfigurationsTip;
QString Helper::createGitReposiory;
QString Helper::createGitReposioryTip;
QString Helper::logCurrentFile;
QString Helper::logCurrentFileTip;
QString Helper::stageCurrentFileForCommit;
QString Helper::stageCurrentFileForCommitTip;
QString Helper::unstageCurrentFileFromCommit;
QString Helper::unstageCurrentFileFromCommitTip;
QString Helper::commitFiles;
QString Helper::commitFilesTip;
QString Helper::resume;
QString Helper::interrupt;
QString Helper::exit;
QString Helper::stepOver;
QString Helper::stepInto;
QString Helper::stepReturn;
QString Helper::attachToRunningProcess;
QString Helper::attachToRunningProcessTip;
QString Helper::crashReport;
QString Helper::parsingFailedJson;
QString Helper::expandAll;
QString Helper::collapseAll;
QString Helper::version;
QString Helper::unlimited;
QString Helper::simulationOutput;
QString Helper::cancelSimulation;
QString Helper::fetchInterfaceData;
QString Helper::fetchInterfaceDataTip;
QString Helper::alignInterfaces;
QString Helper::alignInterfacesTip;
QString Helper::tlmCoSimulationSetup;
QString Helper::tlmCoSimulationSetupTip;
QString Helper::tlmCoSimulation;
QString Helper::animationChooseFile;
QString Helper::animationChooseFileTip;
QString Helper::animationInitialize;
QString Helper::animationInitializeTip;
QString Helper::animationPlay;
QString Helper::animationPlayTip;
QString Helper::animationPause;
QString Helper::animationPauseTip;
QString Helper::simulationParams;
QString Helper::simulationParamsTip;
QString Helper::newModel;
QString Helper::addSystem;
QString Helper::addSystemTip;
QString Helper::addSubModel;
QString Helper::addSubModelTip;
QString Helper::addBus;
QString Helper::addBusTip;
QString Helper::editBus;
QString Helper::addTLMBus;
QString Helper::addTLMBusTip;
QString Helper::editTLMBus;
QString Helper::addConnector;
QString Helper::addConnectorTip;
QString Helper::addBusConnection;
QString Helper::editBusConnection;
QString Helper::addTLMConnection;
QString Helper::editTLMConnection;
QString Helper::running;
QString Helper::finished;
QString Helper::newVariable;
QString Helper::library;
QString Helper::moveUp;
QString Helper::moveDown;
QString Helper::fixErrorsManually;
QString Helper::revertToLastCorrectVersion;
QString Helper::translationFlagsTip;
QString Helper::saveExperimentAnnotation;
QString Helper::saveOpenModelicaSimulationFlagsAnnotation;
QString Helper::saveOpenModelicaCommandLineOptionsAnnotation;
QString Helper::item;
QString Helper::bold;
QString Helper::italic;
QString Helper::underline;
QString Helper::condition;
QString Helper::immediate;
QString Helper::synchronize;
QString Helper::priority;
QString Helper::secs;
QString Helper::saveContentsInOneFile;
QString Helper::OMSSimulateTip;
QString Helper::dateTime;
QString Helper::startTime;
QString Helper::stopTime;
QString Helper::status;
QString Helper::speed;
QString Helper::instantiateOMSModelTip;
QString Helper::terminateInstantiation;
QString Helper::terminateInstantiationTip;
QString Helper::archivedSimulations;
QString Helper::systemSimulationInformation;
QString Helper::translationFlags;

void Helper::initHelperVariables()
{
  /* Global translated variables */
  Helper::newModelicaClass = tr("New Modelica Class");
  Helper::createNewModelicaClass = tr("Create New Modelica Class");
  Helper::openModelicaFiles = tr("Open Model/Library File(s)");
  Helper::openConvertModelicaFiles = tr("Open/Convert Modelica File(s) With Encoding");
  Helper::libraries = tr("Libraries");
  Helper::clearRecentFiles = tr("Clear Recent Files");
  Helper::encoding = tr("Encoding:");
  Helper::fileLabel = tr("File:");
  Helper::file = tr("File");
  Helper::folder = tr("Folder");
  Helper::browse = tr("Browse...");
  Helper::ok = tr("OK");
  Helper::cancel = tr("Cancel");
  Helper::reset = tr("Reset");
  Helper::close = tr("Close");
  Helper::error = tr("Error");
  Helper::chooseFile = tr("Choose File");
  Helper::chooseFiles = tr("Choose File(s)");
  Helper::attributes = tr("Attributes");
  Helper::properties = tr("Properties");
  Helper::add = tr("Add");
  Helper::edit = tr("Edit");
  Helper::save = tr("Save");
  Helper::saveTip = tr("Save a file");
  Helper::saveAs = tr("Save As");
  Helper::saveAsTip = tr("Save a copy of the class in a new file");
  Helper::saveTotal = tr("Save Total");
  Helper::saveTotalTip = tr("Save class with all used classes");
  Helper::apply = tr("Apply");
  Helper::importFMU = tr("Import FMU");
  Helper::chooseDirectory = tr("Choose Directory");
  Helper::general = tr("General");
  Helper::output = tr("Output");
  Helper::parameters = tr("Parameters");
  Helper::inputs = tr("Inputs");
  Helper::name = tr("Name:");
  Helper::comment = tr("Comment:");
  Helper::path = tr("Path:");
  Helper::type = tr("Type");
  Helper::information = tr("Information");
  Helper::rename = tr("Rename");
  Helper::renameTip = tr("Renames an item");
  Helper::OMSRenameTip = tr("OMSimulator rename");
  Helper::checkModel = tr("Check Model");
  Helper::checkModelTip = tr("Check the Modelica class");
  Helper::checkAllModels = tr("Check All Models");
  Helper::checkAllModelsTip = tr("Checks all nested modelica classes");
  Helper::instantiateModel = tr("Instantiate Model");
  Helper::instantiateModelTip = tr("Instantiate/Flatten the Modelica class");
  Helper::FMU = tr("FMU");
  Helper::exportFMUTip = tr("Exports the model as Functional Mockup Unit (FMU)");
  Helper::exportReadonlyPackage = tr("Read-only Package");
  Helper::exportRealonlyPackageTip = tr("Exports the package as read-only package");
  Helper::exportEncryptedPackage = tr("Encrypted Package");
  Helper::exportEncryptedPackageTip = tr("Exports the package as Encrytped package");
  Helper::importFMU = tr("Import FMU");
  Helper::importFMUTip = tr("Imports the model from Functional Mockup Interface (FMU)");
  Helper::exportXML = tr("XML");
  Helper::exportXMLTip = tr("Exports the model as XML");
  Helper::exportToOMNotebook = tr("Export to OMNotebook");
  Helper::exportToOMNotebookTip = tr("Exports the current model to OMNotebook");
  Helper::importFromOMNotebook = tr("Import from OMNotebook");
  Helper::importNgspiceNetlist = tr("Import ngspice netlist");
  Helper::importFromOMNotebookTip = tr("Imports the model(s) from OMNotebook");
  Helper::importNgspiceNetlistTip = tr("Converts ngspice netlist(s) to Modelica code");
  Helper::line = tr("Line");
  Helper::exportAsImage = tr("Export as an Image");
  Helper::exportAsImageTip = tr("Exports the current model to Image");
  Helper::exportFigaro = tr("Export Figaro");
  Helper::exportFigaroTip = tr("Exports the current model to Figaro");
  Helper::OpenModelicaCompilerCLI = tr("OpenModelica Compiler CLI");
  Helper::deleteStr = tr("Delete");
  Helper::copy = tr("Copy");
  Helper::paste = tr("Paste");
  Helper::resetZoom = tr("Reset Zoom");
  Helper::zoomIn = tr("Zoom In");
  Helper::zoomOut = tr("Zoom Out");
  Helper::loading = tr("Loading");
  Helper::question = tr("Question");
  Helper::search = tr("Search");
  Helper::duplicate = tr("Duplicate");
  Helper::duplicateTip = tr("Duplicates the item");
  Helper::unloadClass = tr("Unload");
  Helper::unloadClassTip = tr("Unload the Modelica class");
  Helper::unloadCompositeModelOrTextTip = tr("Unloads the CompositeModel/Text file");
  Helper::unloadOMSModelTip = tr("Unloads the model");
  Helper::refresh = tr("Refresh");
  Helper::simulate = tr("Simulate");
  Helper::simulateTip = tr("Simulates the Modelica class");
  Helper::callFunction = tr("Call function");
  Helper::callFunctionTip = tr("Calls the Modelica function");
  Helper::reSimulate = tr("Re-simulate");
  Helper::reSimulateTip = tr("Re-simulates the Modelica class");
  Helper::reSimulateSetup = tr("Re-simulate Setup");
  Helper::reSimulateSetupTip = tr("Setup re-simulation settings");
  Helper::exportVariables = tr("Export Variables");
  Helper::simulateWithTransformationalDebugger = tr("Simulate with Transformational Debugger");
  Helper::simulateWithTransformationalDebuggerTip = tr("Simulates the Modelica class with Transformational Debugger");
  Helper::simulateWithAlgorithmicDebugger = tr("Simulate with Algorithmic Debugger");
  Helper::simulateWithAlgorithmicDebuggerTip = tr("Simulates the Modelica class with Algorithmic Debugger");
  Helper::simulateWithAnimation = tr("Simulate with Animation");
  Helper::simulateWithAnimationTip = tr("Simulates the Modelica class with Animation");
  Helper::simulationSetup = tr("Simulation Setup");
  Helper::simulationSetupTip = tr("Setup simulation settings");
  Helper::simulation = tr("Simulation");
  Helper::reSimulation = tr("Re-simulation");
  Helper::interactiveSimulation = tr("Interactive Simulation");
  Helper::options = tr("Options");
  Helper::extent = tr("Extent");
  Helper::bottom = tr("Bottom:");
  Helper::top = tr("Top:");
  Helper::grid = tr("Grid");
  Helper::horizontal = tr("Horizontal");
  Helper::vertical = tr("Vertical");
  Helper::component = tr("Component");
  Helper::scaleFactor = tr("Scale factor:");
  Helper::preserveAspectRatio = tr("Preserve aspect ratio");
  Helper::originX = tr("OriginX:");
  Helper::originY = tr("OriginY:");
  Helper::rotation = tr("Rotation:");
  Helper::thickness = tr("Thickness:");
  Helper::smooth = tr("Smooth:");
  Helper::bezier = tr("Bezier");
  Helper::startArrow = tr("Start Arrow:");
  Helper::endArrow = tr("End Arrow:");
  Helper::arrowSize = tr("Arrow Size:");
  Helper::size = tr("Size:");
  Helper::lineStyle = tr("Line Style");
  Helper::color = tr("Color:");
  Helper::Colors = tr("Colors");
  Helper::fontFamily = tr("Font Family:");
  Helper::fontSize = tr("Font Size:");
  Helper::pickColor = tr("Pick Color");
  Helper::fillStyle = tr("Fill Style");
  Helper::pattern = tr("Pattern:");
  Helper::extent1X = tr("Extent1X:");
  Helper::extent1Y = tr("Extent1Y:");
  Helper::extent2X = tr("Extent2X:");
  Helper::extent2Y = tr("Extent2Y:");
  Helper::radius = tr("Radius:");
  Helper::startAngle = tr("Start Angle:");
  Helper::endAngle = tr("End Angle:");
  Helper::curveStyle = tr("Curve Style");
  Helper::figaro = tr("Figaro");
  Helper::remove = tr("Remove");
  Helper::fileLocation = tr("Location", "For files");
  Helper::errorLocation = tr("Location", "For errors");
  Helper::readOnly = tr("Read-Only");
  Helper::writable = tr("Writable");
  Helper::workingDirectory = tr("Working Directory:");
  Helper::iconView = tr("Icon View");
  Helper::diagramView = tr("Diagram View");
  Helper::textView = tr("Text View");
  Helper::documentationView = tr("Documentation View");
  Helper::filterClasses = tr("Filter Classes");
  Helper::findReplaceModelicaText = tr("Find/Replace...");
  Helper::left = tr("Left");
  Helper::center = tr("Center");
  Helper::right = tr("Right");
  Helper::createConnection = tr("Create Connection");
  Helper::connectionAttributes = tr("Connection Attributes");
  Helper::createTransition = tr("Create Transition");
  Helper::editTransition = tr("Edit Transition");
  Helper::findVariables = tr("Find Variables");
  Helper::filterVariables = tr("Filter Variables");
  Helper::openClass = tr("Open Class");
  Helper::openClassTip = tr("Opens the class details");
  Helper::viewIcon = tr("View Icon");
  Helper::viewIconTip = tr("Opens the class icon");
  Helper::viewDiagram = tr("View Diagram");
  Helper::viewDiagramTip = tr("Opens the class diagram");
  Helper::viewText = tr("View Text");
  Helper::viewTextTip = tr("Opens the class text");
  Helper::viewDocumentation = tr("View Documentation");
  Helper::viewDocumentationTip = tr("Opens the class documentation");
  Helper::dontShowThisMessageAgain = tr("Don't show this message again");
  Helper::clickAndDragToResize = tr("Click and drag to resize");
  Helper::variables = tr("Variables");
  Helper::variablesBrowser = tr("Variables Browser");
  Helper::description = tr("Description");
  Helper::previous = tr("Previous");
  Helper::next = tr("Next");
  Helper::reload = tr("Reload");
  Helper::index = tr("Index");
  Helper::equation = tr("Equation");
  Helper::transformationalDebugger = tr("Transformational Debugger");
  Helper::executionCount = tr("Executions");
  Helper::executionMaxTime = tr("Max time");
  Helper::executionTime = tr("Time");
  Helper::executionFraction = tr("Fraction");
  Helper::debuggingFileNotSaveInfo = tr("<b>Info: </b>Update the actual model in <b>Modeling</b> perspective and simulate again. This is only shown for debugging purpose. Your changes will not be saved.");
  Helper::algorithmicDebugger = tr("Algorithmic Debugger");
  Helper::debugConfigurations = tr("Debug Configurations");
  Helper::debugConfigurationsTip = tr("Manage debug configurations");
  Helper::createGitReposiory = tr("Create Repository");
  Helper::createGitReposioryTip = tr("Create a Git repository");
  Helper::logCurrentFile = tr("Log Current File");
  Helper::logCurrentFileTip = tr("Logging current file");
  Helper::stageCurrentFileForCommit = tr("Stage Current File");
  Helper::stageCurrentFileForCommitTip = tr("Staging current file for next commit");
  Helper::unstageCurrentFileFromCommit = tr("Unstage Current File");
  Helper::unstageCurrentFileFromCommitTip = tr("Unstaging current file from next commit");
  Helper::commitFiles = tr("Commit");
  Helper::commitFilesTip = tr("Commiting modified files to the repository");
  Helper::resume = tr("Resume");
  Helper::interrupt = tr("Interrupt");
  Helper::exit = tr("Exit");
  Helper::stepOver = tr("Step Over");
  Helper::stepInto = tr("Step Into");
  Helper::stepReturn = tr("Step Return");
  Helper::attachToRunningProcess = tr("Attach to Running Process");
  Helper::attachToRunningProcessTip = tr("Attach the debugger to running process");
  Helper::crashReport = tr("Crash Report");
  Helper::parsingFailedJson = tr("Parsing of JSON file failed");
  Helper::expandAll = tr("Expand All");
  Helper::collapseAll = tr("Collapse All");
  Helper::version = tr("Version");
  Helper::unlimited = tr("unlimited");
  Helper::simulationOutput = tr("Simulation Output");
  Helper::cancelSimulation = tr("Cancel Simulation");
  Helper::fetchInterfaceData = tr("Fetch Interface Data");
  Helper::fetchInterfaceDataTip = tr("Fetches the interface data");
  Helper::alignInterfaces = tr("Align Interfaces");
  Helper::alignInterfacesTip = tr("Aligns the interfaces");
  Helper::tlmCoSimulationSetup = tr("TLM Co-Simulation Setup");
  Helper::tlmCoSimulationSetupTip = tr("Opens the TLM co-simulation setup");
  Helper::tlmCoSimulation = tr("TLM Co-Simulation");
  Helper::animationChooseFile = tr("Animation File");
  Helper::animationChooseFileTip = tr("Open an animation.");
  Helper::animationInitialize = tr("Initialize");
  Helper::animationInitializeTip = tr("Initialize the animation scene");
  Helper::animationPlay = tr("Play");
  Helper::animationPlayTip = tr("Play the animation");
  Helper::animationPause = tr("Pause");
  Helper::animationPauseTip = tr("Pause the animation");
  Helper::simulationParams = tr("Simulation Parameters");
  Helper::simulationParamsTip = tr("Shows the Simulation Parameters dialog");
  Helper::newModel = tr("New OMSimulator Model");
  Helper::addSystem = tr("Add System");
  Helper::addSystemTip = tr("Adds the System i.e., FMI or TLM");
  Helper::addSubModel = tr("Add SubModel");
  Helper::addSubModelTip = tr("Adds the SubModel i.e., FMU or Table");
  Helper::addBus = tr("Add Bus");
  Helper::addBusTip = tr("Adds the bus");
  Helper::editBus = tr("Edit Bus");
  Helper::addTLMBus = tr("Add TLM Bus");
  Helper::addTLMBusTip = tr("Adds the TLM bus");
  Helper::editTLMBus = tr("Edit TLM Bus");
  Helper::addConnector = tr("Add Connector");
  Helper::addConnectorTip = tr("Adds the connector");
  Helper::addBusConnection = tr("Add Bus Connection");
  Helper::editBusConnection = tr("Edit Bus Connection");
  Helper::addTLMConnection = tr("Add TLM Connection");
  Helper::editTLMConnection = tr("Edit TLM Connection");
  Helper::running = tr("Running");
  Helper::finished = tr("Finished");
  Helper::newVariable = tr("<New Variable>");
  Helper::library = tr("Library");
  Helper::moveUp = tr("Move Up");
  Helper::moveDown = tr("Move Down");
  Helper::fixErrorsManually = tr("Fix error(s) manually");
  Helper::revertToLastCorrectVersion = tr("Revert to last correct version");
  Helper::translationFlagsTip = tr("Space separated list of OMC command line options e.g., -d=initialization --cheapmatchingAlgorithm=3");
  Helper::saveExperimentAnnotation = tr("Save experiment annotation inside model i.e., experiment annotation");
  Helper::saveOpenModelicaSimulationFlagsAnnotation = tr("Save simulation flags inside model i.e., __OpenModelica_simulationFlags annotation");
  Helper::saveOpenModelicaCommandLineOptionsAnnotation = tr("Save translation flags inside model i.e., __OpenModelica_commandLineOptions annotation");
  Helper::item = tr("item");
  Helper::bold = tr("Bold");
  Helper::italic = tr("Italic");
  Helper::underline = tr("Underline");
  Helper::condition = tr("Condition:");
  Helper::immediate = tr("Immediate");
  Helper::synchronize = tr("Synchronize");
  Helper::priority = tr("Priority:");
  Helper::secs = tr("secs");
  Helper::saveContentsInOneFile = tr("Save contents in one file");
  Helper::OMSSimulateTip = tr("Simulates the OMSimulator model");
  Helper::dateTime = tr("DateTime");
  Helper::startTime = tr("Start Time");
  Helper::stopTime = tr("Stop Time");
  Helper::status = tr("Status");
  Helper::speed = tr("Speed:");
  Helper::instantiateOMSModelTip = tr("Instantiates the OMSimulator model");
  Helper::terminateInstantiation = tr("Terminate Instantiation");
  Helper::terminateInstantiationTip = tr("Terminates the model instantiation");
  Helper::archivedSimulations = tr("Archived Simulations");
  Helper::systemSimulationInformation = tr("System Simulation Information");
  Helper::translationFlags = tr("Translation Flags");
}

QString GUIMessages::getMessage(int type)
{
  switch (type)
  {
    case CHECK_MESSAGES_BROWSER:
      return tr("Please check the Messages Browser for more error specific details.");
    case SAME_COMPONENT_NAME:
      return tr("A component with the name <b>%1</b> already exists. Please choose another name.");
    case SAME_COMPONENT_CONNECT:
      return tr("You cannot connect a component to itself.");
    case NO_MODELICA_CLASS_OPEN:
      return tr("There is no Modelica Class opened for %1.");
    case SIMULATION_STARTTIME_LESSTHAN_STOPTIME:
      return tr("Simulation Start Time should be less than or equal to Stop Time.");
    case ENTER_NAME:
      return tr("Please enter <b>%1</b> Name.");
    case EXTENDS_CLASS_NOT_FOUND:
      return tr("Extends class <b>%1</b> does not exist.");
    case INSERT_IN_CLASS_NOT_FOUND:
      return tr("Insert in class <b>%1</b> does not exist.");
    case INSERT_IN_SYSTEM_LIBRARY_NOT_ALLOWED:
      return tr("Insert in class <b>%1</b> is a system library. System libraries are read-only.");
    case MODEL_ALREADY_EXISTS:
      return tr("<b>%1</b> <i>%2</i> already exists in <b>%3</b>.");
    case ITEM_ALREADY_EXISTS:
      return tr("An item with the same name already exists. Please try some other name.");
    case OPENMODELICAHOME_NOT_FOUND:
      return tr("Could not find environment variable OPENMODELICAHOME. Please make sure OpenModelica is installed properly.");
    case ERROR_OCCURRED:
      return tr("Following error has occurred.<br />%1");
    case ERROR_IN_TEXT:
      return tr("Problems are found in %1 Text. <br />");
    case REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY:
      return tr("<br /><br />If you cannot find the source of the error, you can always <b>revert to the last correct version</b>.");
    case NO_OPENMODELICA_KEYWORDS:
      return tr("Please make sure you are not using any OpenModelica Keywords like (model, package, record, class etc.)");
    case UNABLE_TO_LOAD_FILE:
      return tr("Error has occurred while loading the file/library <b>%1</b>. Unable to load the file/library.");
    case UNABLE_TO_OPEN_FILE:
      return tr("Unable to open file <b>%1</b>.");
    case UNABLE_TO_SAVE_FILE:
      return tr("Unable to save the file <b>%1</b>. %2");
    case UNABLE_TO_DELETE_FILE:
      return tr("Unable to delete <b>%1</b>.");
    case FILE_NOT_FOUND:
      return tr("The file <b>%1</b> not found.");
    case ERROR_OPENING_FILE:
      return tr("Error opening the file <b>%1</b>. %2");
    case UNABLE_TO_LOAD_MODEL:
      return tr("Error has occurred while loading the model : \n%1.");
    case DELETE_AND_LOAD:
      return tr("Delete the existing class(es) before loading the file/library <b>%1</b>.");
    case REDEFINING_EXISTING_CLASSES:
      return tr("Redefining class(es) <b>%1</b> which already exist(s).");
    case MULTIPLE_TOP_LEVEL_CLASSES:
      return tr("Only single nonstructured entity is allowed to be stored in the file. <b>%1</b> contains following classes <b>%2</b>.");
    case DIAGRAM_VIEW_DROP_MSG:
      return tr("You cannot insert <b>%1</b>, it is a <b>%2</b>. Only <b>model</b>, <b>class</b>, <b>connector</b>, <b>record</b> or <b>block</b> is allowed on the diagram layer.");
    case ICON_VIEW_DROP_MSG:
      return tr("You cannot insert <b>%1</b>, it is a <b>%2</b>. Only <b>connector</b> is allowed on the icon layer.");
    case PLOT_PARAMETRIC_DIFF_FILES:
      return tr("You cannot do a plot parametric between two different simulation result files. Make sure you select two variables from the same simulation result file.");
    case ENTER_VALID_NUMBER:
      return tr("Enter a valid number value for <b>%1</b>.");
    case ENTER_VALUE:
      return tr("Enter a value for <b>%1</b>.");
    case ITEM_DROPPED_ON_ITSELF:
      return tr("You cannot drop an item on itself.");
    case MAKE_REPLACEABLE_IF_PARTIAL:
      return tr("The <b>%1</b> <i>%2</i> is defined as <b>partial</b>.<br />The component will be added as a <b>replaceable</b> component.");
    case INNER_MODEL_NAME_CHANGED:
      return tr("A component with the name <b>%1</b> already exists. The name is changed from <b>%1</b> to <b>%2</b>.<br /><br />This is probably wrong because the component is declared as <b>inner</b>.");
    case FMU_GENERATED:
      return tr("The FMU is generated at <b>%1</b>.");
    case FMU_MOVE_FAILED:
      return tr("Cannot move FMU to <b>%1</b>.");
    case FMU_EMPTY_PLATFORMS:
      return tr("A source-only FMU will be generated because an empty list of platforms is selected. If this is not intended, check settings in <b>%1->FMI->Platforms</b>.");
    case XML_GENERATED:
      return tr("The XML is generated at <b>%1</b>.");
    case FIGARO_GENERATED:
      return tr("The FIGARO is generated.");
    case ENCRYPTED_PACKAGE_GENERATED:
      return tr("The encrytped package is generated at <b>%1</b>.");
    case READONLY_PACKAGE_GENERATED:
      return tr("The read-only package is generated at <b>%1</b>.");
    case UNLOAD_CLASS_MSG:
      return tr("Are you sure you want to unload <b>%1</b>? Everything contained inside this class will also be unloaded.");
    case DELETE_CLASS_MSG:
      return tr("Are you sure you want to delete <b>%1</b>? Everything contained inside this class will also be deleted.");
    case UNLOAD_TEXT_FILE_MSG:
      return tr("Are you sure you want to unload <b>%1</b>?");
    case DELETE_TEXT_FILE_MSG:
      return tr("Are you sure you want to delete <b>%1</b>?<br /><br />This will also delete from file system.");
    case WRONG_MODIFIER:
      return tr("The Modifier <b>%1</b> format is invalid. The correct format is <b>phi(start=1)</b>");
    case SET_INFO_XML_FLAG:
      return tr("The operations were not generated. Check Generate Operations in <b>%1->Debugger->Transformational Debugger</b> OR you must set the -d=infoXmlOperations flag via <b>%2->Simulation->OMC Command Line Options</b> and simulate again.");
    case DEBUG_CONFIGURATION_EXISTS_MSG:
      return tr("A debug configuration with name <b>%1</b> already exists. Error occurred while saving the debug configuration <b>%2<b>.");
    case DEBUG_CONFIGURATION_SIZE_EXCEED:
      return tr("Maximum <b>%1</b> debug configurations are allowed.");
    case DELETE_DEBUG_CONFIGURATION_MSG:
      return tr("Are you sure you want to delete <b>%1</b> debug configuration?");
    case DEBUGGER_ALREADY_RUNNING:
      return tr("A debugging session is already running. Only one debugging session is allowed.");
    case CLASS_NOT_FOUND:
      return tr("Unable to find the class <b>%1</b>.");
    case BREAKPOINT_INSERT_NOT_SAVED:
      return tr("The class <b>%1</b> is not saved. Breakpoints are only allowed on saved classes.");
    case BREAKPOINT_INSERT_NOT_MODELICA_CLASS:
      return tr("The class <b>%1</b> is not a modelica class. Breakpoints are only allowed on modelica classes.");
    case TLMMANAGER_NOT_SET:
      return tr("TLM Manager executable path is not set. Set it via <b>%1->TLM</b>");
    case COMPOSITEMODEL_UNSAVED:
      return tr("CompositeModel <b>%1</b> has unsaved changes. Do you want to save?");
    case TLMCOSIMULATION_ALREADY_RUNNING:
      return tr("TLM co-simulation session is already running. Only one session is allowed.");
    case TERMINAL_COMMAND_NOT_SET:
      return tr("Terminal command is not set. You can define a new terminal command in <b>%1->General->Terminal Command</b>.");
    case UNABLE_FIND_COMPONENT_IN_CONNECTION:
      return tr("Unable to find component %1 while parsing connection %2.");
    case UNABLE_FIND_COMPONENT_IN_TRANSITION:
      return tr("Unable to find component %1 while parsing transition(%2).");
    case UNABLE_FIND_COMPONENT_IN_INITIALSTATE:
      return tr("Unable to find component %1 while parsing initialState(%2).");
    case SELECT_SIMULATION_OPTION:
      return tr("Select at least one of the following options, <br /><br />* %1<br />* %2<br />* %3<br />* %4")
          .arg(Helper::saveExperimentAnnotation)
          .arg(Helper::saveOpenModelicaCommandLineOptionsAnnotation)
          .arg(Helper::saveOpenModelicaSimulationFlagsAnnotation)
          .arg(Helper::simulate);
    case INVALID_TRANSITION_CONDITION:
      return tr("Please enter a valid condition e.g., x >=0.");
    case MULTIPLE_DECLARATIONS_COMPONENT:
      return tr("Multiple declarations of component <b>%1</b> are found.");
    case GDB_ERROR:
      return tr("Following error has occurred <b>%1</b> GDB arguments are <b>\"%2\"</b>");
    case INVALID_INSTANCE_NAME:
      return tr("Name <b>%1</b> is not a valid identifier.<br />A name must start with a letter, and all characters must be letters or digits. It may not be a reserved word.");
    default:
      return "";
  }
}
