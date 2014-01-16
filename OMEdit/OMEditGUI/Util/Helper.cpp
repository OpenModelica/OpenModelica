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
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE. 
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
 * 
 * @author Adeel Asghar <adeel.asghar@liu.se>
 *
 * RCS: $Id$
 *
 */

#include "Helper.h"

/* Global non-translated variables */
QString Helper::applicationName = "OMEdit";
QString Helper::applicationIntroText = "OpenModelica Connection Editor";
QString Helper::organization = "openmodelica";  /* case-sensitive string. Don't change it. Used by ini settings file. */
QString Helper::application = "omedit"; /* case-sensitive string. Don't change it. Used by ini settings file. */
// these two variables are set once we are connected to OMC......in OMCProxy::startServer().
QString Helper::OpenModelicaHome = "";
QString Helper::OpenModelicaLibrary = "";
QString Helper::OMCServerName = "OMEdit";
QString Helper::omFileTypes = "Modelica Files (*.mo)";
QString Helper::omnotebookFileTypes = "OMNotebook Files (*.onb *.onbz *.nb)";
QString Helper::imageFileTypes = "SVG (*.svg);;PNG image (*.png);;Windows BMP image (*.bmp);;JPEG (*.jpg *.jpeg)";
QString Helper::bitmapFileTypes = "PNG image (*.png);;Windows BMP image (*.bmp);;JPEG (*.jpg *.jpeg)";
QString Helper::fmuFileTypes = "FMU Files (*.fmu)";
QString Helper::xmlFileTypes = "XML Files (*.xml)";
QString Helper::matFileTypes = "MAT Files (*.mat)";
QString Helper::omResultFileTypes = "OpenModelica Result Files (*.mat *.plt *.csv)";
int Helper::treeIndentation = 13;
QSize Helper::iconSize = QSize(20, 20);
QSize Helper::buttonIconSize = QSize(16, 16);
int Helper::tabWidth = 20;
QString Helper::modelicaComponentFormat = "image/modelica-component";
QString Helper::modelicaFileFormat = "text/uri-list";
qreal Helper::shapesStrokeWidth = 2.0;
int Helper::headingFontSize = 18;
QString Helper::ModelicaSimulationMethods = "dassl,euler,rungekutta,inline-euler,inline-rungekutta,dasslwort,radau1,radau3,radau5,lobatto2,lobatto4";
QString Helper::ModelicaInitializationMethods = ",none,numeric,symbolic";
QString Helper::ModelicaOptimizationMethods = ",nelder_mead_ex,nelder_mead_ex2,simplex,newuoa";
QString Helper::ModelicaSimulationOutputFormats = "mat,plt,csv,empty";
QString Helper::clockOptions = ",RT,CYC,CPU";
QString Helper::linearSolvers = ",lapack";
QString Helper::nonLinearSolvers = ",hybrid,kinsol,newton";
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
QString Helper::utf8 = "UTF-8";
QFontInfo Helper::systemFontInfo = QFontInfo(QFont());
QFontInfo Helper::monospacedFontInfo = QFontInfo(QFont());
QString Helper::defaultComponentAnnotationString = QString("{-100.0,-100.0,100.0,100.0,true,0.1,2.0,2.0,"
                                                  "{Rectangle(true, {0.0, 0.0}, 0, {0, 0, 0}, {240, 240, 240}, LinePattern.Solid, FillPattern.Solid, 0.25, BorderPattern.None, {{-100, 100}, {100, -100}}, 0),"
                                                  "Text(true, {0.0, 0.0}, 0, {0, 0, 0}, {0, 0, 0}, LinePattern.Solid, FillPattern.None, 0.25, {{-100, 20}, {100, -20}}, \"%name\", 0, TextAlignment.Center)}}");
QString Helper::errorComponentAnnotationString = QString("{-100.0,-100.0,100.0,100.0,false,0.1,2.0,2.0,"
                                                         "{Rectangle(true, {0.0, 0.0}, 0, {255, 0, 0}, {0, 0, 0}, LinePattern.Solid, FillPattern.None, 0.25, BorderPattern.None, {{-100, -100}, {100, 100}}, 0),"
                                                         "Line(true, {0.0, 0.0}, 0, {{-100, 100}, {100, -100}}, {255, 0, 0}, LinePattern.Solid, 0.25, {Arrow.None, Arrow.None}, 3, Smooth.None),"
                                                         "Line(true, {0.0, 0.0}, 0, {{100, 100}, {-100, -100}}, {255, 0, 0}, LinePattern.Solid, 0.25, {Arrow.None, Arrow.None}, 3, Smooth.None)}}");
/* Global translated variables */
QString Helper::newModelicaClass;
QString Helper::createNewModelicaClass;
QString Helper::findClasses;
QString Helper::openModelicaFiles;
QString Helper::openConvertModelicaFiles;
QString Helper::libraries;
QString Helper::clearRecentFiles;
QString Helper::encoding;
QString Helper::file;
QString Helper::browse;
QString Helper::ok;
QString Helper::cancel;
QString Helper::close;
QString Helper::error;
QString Helper::chooseFile;
QString Helper::chooseFiles;
QString Helper::attributes;
QString Helper::properties;
QString Helper::edit;
QString Helper::save;
QString Helper::chooseDirectory;
QString Helper::general;
QString Helper::output;
QString Helper::parameters;
QString Helper::name;
QString Helper::comment;
QString Helper::path;
QString Helper::type;
QString Helper::information;
QString Helper::rename;
QString Helper::checkModel;
QString Helper::checkModelTip;
QString Helper::instantiateModel;
QString Helper::instantiateModelTip;
QString Helper::exportFMU;
QString Helper::exportFMUTip;
QString Helper::importFMU;
QString Helper::importFMUTip;
QString Helper::exportXML;
QString Helper::exportXMLTip;
QString Helper::exportToOMNotebook;
QString Helper::exportToOMNotebookTip;
QString Helper::importFromOMNotebook;
QString Helper::importFromOMNotebookTip;
QString Helper::exportAsImage;
QString Helper::exportAsImageTip;
QString Helper::deleteStr;
QString Helper::copy;
QString Helper::paste;
QString Helper::loading;
QString Helper::question;
QString Helper::search;
QString Helper::unloadClass;
QString Helper::unloadClassTip;
QString Helper::simulate;
QString Helper::simulateTip;
QString Helper::simulationSetup;
QString Helper::simulationSetupTip;
QString Helper::simulation;
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
QString Helper::remove;
QString Helper::fileLocation;
QString Helper::errorLocation;
QString Helper::readOnly;
QString Helper::writable;
QString Helper::iconView;
QString Helper::diagramView;
QString Helper::modelicaTextView;
QString Helper::documentationView;
QString Helper::searchModelicaClass;
QString Helper::findReplaceModelicaText;
QString Helper::left;
QString Helper::center;
QString Helper::right;
QString Helper::connectArray;
QString Helper::findVariables;
QString Helper::viewClass;
QString Helper::viewClassTip;
QString Helper::viewDocumentation;
QString Helper::viewDocumentationTip;
QString Helper::dontShowThisMessageAgain;
QString Helper::clickAndDragToResize;
QString Helper::variables;
QString Helper::description;
QString Helper::previous;
QString Helper::next;
QString Helper::index;
QString Helper::equation;

void Helper::initHelperVariables()
{
  /* Global translated variables */
  Helper::newModelicaClass = tr("New Modelica Class");
  Helper::createNewModelicaClass = tr("Create New Modelica Class");
  Helper::findClasses = tr("Find Classes");
  Helper::openModelicaFiles = tr("Open Model/Library File(s)");
  Helper::openConvertModelicaFiles = tr("Open/Convert Modelica File(s) With Encoding");
  Helper::libraries = tr("Libraries");
  Helper::clearRecentFiles = tr("Clear Recent Files");
  Helper::encoding = tr("Encoding:");
  Helper::file = tr("File:");
  Helper::browse = tr("Browse...");
  Helper::ok = tr("OK");
  Helper::cancel = tr("Cancel");
  Helper::close = tr("Close");
  Helper::error = tr("Error");
  Helper::chooseFile = tr("Choose File");
  Helper::chooseFiles = tr("Choose File(s)");
  Helper::attributes = tr("Attributes");
  Helper::properties = tr("Properties");
  Helper::edit = tr("Edit");
  Helper::save = tr("Save");
  Helper::importFMU = tr("Import FMU");
  Helper::chooseDirectory = tr("Choose Directory");
  Helper::general = tr("General");
  Helper::output = tr("Output");
  Helper::parameters = tr("Parameters");
  Helper::name = tr("Name:");
  Helper::comment = tr("Comment:");
  Helper::path = tr("Path:");
  Helper::type = tr("Type");
  Helper::information = tr("Information");
  Helper::rename = tr("rename");
  Helper::checkModel = tr("Check Model");
  Helper::checkModelTip = tr("Check the Modelica class");
  Helper::instantiateModel = tr("Instantiate Model");
  Helper::instantiateModelTip = tr("Instantiate/Flatten the Modelica class");
  Helper::exportFMU = tr("Export FMU");
  Helper::exportFMUTip = tr("Exports the model as Functional Mockup Unit (FMU)");
  Helper::importFMU = tr("Import FMU");
  Helper::importFMUTip = tr("Imports the model from Functional Mockup Interface (FMU)");
  Helper::exportXML = tr("Export XML");
  Helper::exportXMLTip = tr("Exports the model as XML");
  Helper::exportToOMNotebook = tr("Export to OMNotebook");
  Helper::exportToOMNotebookTip = tr("Exports the current model to OMNotebook");
  Helper::importFromOMNotebook = tr("Import from OMNotebook");
  Helper::importFromOMNotebookTip = tr("Imports the model(s) from OMNotebook");
  Helper::exportAsImage = tr("Export as an Image");
  Helper::exportAsImageTip = tr("Exports the current model to Image");
  Helper::deleteStr = tr("Delete");
  Helper::copy = tr("Copy");
  Helper::paste = tr("Paste");
  Helper::loading = tr("Loading");
  Helper::question = tr("Question");
  Helper::search = tr("Search");
  Helper::unloadClass = tr("Unload");
  Helper::unloadClassTip = tr("Unload the Modelica class");
  Helper::simulate = tr("Simulate");
  Helper::simulateTip = tr("Simulate the Modelica class");
  Helper::simulationSetup = tr("Simulation Setup");
  Helper::simulationSetupTip = tr("Setup simulation settings");
  Helper::simulation = tr("Simulation");
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
  Helper::remove = tr("Remove");
  Helper::fileLocation = tr("Location", "For files");
  Helper::errorLocation = tr("Location", "For errors");
  Helper::readOnly = tr("Read-Only");
  Helper::writable = tr("Writable");
  Helper::iconView = tr("Icon View");
  Helper::diagramView = tr("Diagram View");
  Helper::modelicaTextView = tr("Modelica Text View");
  Helper::documentationView = tr("Documentation View");
  Helper::searchModelicaClass = tr("Search Modelica Class");
  Helper::findReplaceModelicaText = tr("Find/Replace...");
  Helper::left = tr("Left");
  Helper::center = tr("Center");
  Helper::right = tr("Right");
  Helper::connectArray = tr("Connect Array");
  Helper::findVariables = tr("Find Variables");
  Helper::viewClass = tr("View Class");
  Helper::viewClassTip = tr("Opens the class details");
  Helper::viewDocumentation = tr("View Documentation");
  Helper::viewDocumentationTip = tr("Opens the class documentation");
  Helper::dontShowThisMessageAgain = tr("Don't show this message again");
  Helper::clickAndDragToResize = tr("Click and drag to resize");
  Helper::variables = tr("Variables");
  Helper::description = tr("Description");
  Helper::previous = tr("Previous");
  Helper::next = tr("Next");
  Helper::index = tr("Index");
  Helper::equation = tr("Equation");
}

QString GUIMessages::getMessage(int type)
{
  switch (type)
  {
    case CHECK_MESSAGES_BROWSER:
      return tr("Please check the Messages Browser for more error specific details.");
    case SAME_COMPONENT_NAME:
      return tr("A Component with the same name already exists. Please choose another Name.");
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
      return tr("Following Error has occurred. \n\n%1");
    case ERROR_IN_MODELICA_TEXT:
      return tr("Problems are found in Modelica Text. <br />");
    case REVERT_PREVIOUS_OR_FIX_ERRORS_MANUALLY:
      return tr("<br /><br />For normal users it is recommended to choose <b>Revert from previous</b>. You can also choose <b>Fix errors manually</b> if you want to fix them by your own.");
    case NO_OPENMODELICA_KEYWORDS:
      return tr("Please make sure you are not using any OpenModelica Keywords like (model, package, record, class etc.)");
    case UNABLE_TO_LOAD_FILE:
      return tr("Error has occurred while loading the file/library <b>%1</b>. Unable to load the file/library.");
    case FILE_NOT_FOUND:
      return tr("The file <b>%1</b> not found.");
    case ERROR_OPENING_FILE:
      return tr("Error opening the file <b>%1</b>. %2");
    case UNABLE_TO_LOAD_MODEL:
      return tr("Error has occurred while loading the model : \n%1.");
    case DELETE_AND_LOAD:
      return tr("Delete the existing class(es) before loading the file/library <b>%1</b>.");
    case REDEFINING_EXISTING_CLASSES:
      return tr("Redefining class(es) <b>%1</b> which already exists.");
    case MULTIPLE_TOP_LEVEL_CLASSES:
      return tr("Only single nonstructured entity is allowed to be stored in the file. The file <b>%1</b> contains following classes <b>%2</b>.");
    case CLOSE_INTERACTIVE_SIMULATION_TAB:
      return tr("Are you sure you want to close <b>%1</b> interactive simulation?");
    case INFO_CLOSE_INTERACTIVE_SIMULATION_TAB:
      return tr("You cannot recover this window once it is closed.");
    case INTERACTIVE_SIMULATION_RUNNIG:
      return tr("You already have one interactive simulation running. Only one interactive simulation session is allowed at a time. \n\n Please shutdown the interactive simulation or close the interactive simulation tab before launching the new one.");
    case SELECT_VARIABLE_FOR_OMI:
      return tr("Please select a variable to plot before starting.");
    case DIAGRAM_VIEW_DROP_MSG:
      return tr("You cannot insert <b>%1</b>, it is a <b>%2</b>. Only <b>model</b>, <b>class</b>, <b>connector</b>, <b>record</b> or <b>block</b> is allowed on the diagram layer.");
    case ICON_VIEW_DROP_MSG:
      return tr("You cannot insert <b>%1</b>, it is a <b>%2</b>. Only <b>connector</b> is allowed on the icon layer.");
    case PLOT_PARAMETRIC_DIFF_FILES:
      return tr("You cannot do a plot parametric between two different simulation result files. Make sure you select two variables from the same simulation result file.");
    case FILE_FORMAT_NOT_SUPPORTED:
      return tr("The file <b>%1</b> is not a valid Modelica file. The file format is not supported. You can only open <b>%2</b>.");
    case ENTER_VALID_INTEGER:
      return tr("Enter a valid positive integer index value for <b>%1</b>.");
    case ENTER_VALID_NUMBER:
      return tr("Enter a valid number value for <b>%1</b>.");
    case ITEM_DROPPED_ON_ITSELF:
      return tr("You cannot drop an item on itself.");
    case MAKE_REPLACEABLE_IF_PARTIAL:
      return tr("The <b>%1</b> <i>%2</i> is defined as <b>partial</b>.<br />The component will be added as a <b>replaceable</b> component.");
    case INNER_MODEL_NAME_CHANGED:
      return tr("A component with the name <b>%1</b> already exists. The name is changed from <b>%1</b> to <b>%2</b>.<br /><br />This is probably wrong because the component is declared as <b>inner</b>.");
    case FMU_GENERATED:
      return tr("The FMU is generated at %1/%2.fmu");
    case XML_GENERATED:
      return tr("The XML is generated at %1/%2.xml");
    case DELETE_CLASS_MSG:
      return tr("Are you sure you want to unload <b>%1</b>? Everything contained inside this class will also be unloaded.");
    case WRONG_MODIFIER:
      return tr("The Modifier '%1' format is invalid. The correct format is 'phi(start=1)'");
    case SET_INFO_XML_FLAG:
      return tr("The operations were not generated. You must set the +d=infoXmlOperations flag. Enable it via Tools->Options->Simulation->OMC Flags and simulate again.");
    default:
      return "";
  }
}
