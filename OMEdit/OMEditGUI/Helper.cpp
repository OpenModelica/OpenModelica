/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 * Contributors 2011: Abhinn Kothari
 */

/*
 * RCS: $Id$
 */

#include "Helper.h"

/* Global non-translated variables */
QString Helper::applicationName = "OMEdit";
QString Helper::applicationVersion = "Version: 1.9.0";
QString Helper::applicationIntroText = "OpenModelica Connection Editor";
/* Increment this settings number if you change something in the QMainWindow appereance
   * Otherwise OMEdit will load the old settings and Qt make a mess of your toolbars and dockwidgets.
   */
int Helper::settingsVersion = 0;
// these two variables are set once we are connected to OMC......in OMCProxy::startServer().
QString Helper::OpenModelicaHome = "";
QString Helper::OpenModelicaLibrary = "";
// this variables is set in OMCProxy::loadStandardLibrary().
QString Helper::OpenModelicaLibraryVersion = "";
QString Helper::omcServerName = "OMEdit";
QString Helper::omFileTypes = "Modelica Files (*.mo)";
QString Helper::omnotebookFileTypes = "OMNotebook Files (*.onb *.onbz *.nb)";
QString Helper::imageFileTypes = "Image Files (*.png *.svg *.bmp *.jpg)";
QString Helper::fmuFileTypes = "FMU Files (*.fmu)";
QString Helper::xmlFileTypes = "XML Files (*.xml)";
QString Helper::matFileTypes = "MAT Files (*.mat)";
int Helper::treeIndentation = 13;
QSize Helper::iconSize = QSize(20, 20);
QSize Helper::buttonIconSize = QSize(20, 20);
int Helper::tabWidth = 20;
qreal Helper::globalDiagramXScale = 1.0;
qreal Helper::globalDiagramYScale = 1.0;
qreal Helper::globalIconXScale = 0.12;
qreal Helper::globalIconYScale = 0.12;
qreal Helper::shapesStrokeWidth = 5.0;
int Helper::headingFontSize = 18;
QString Helper::ModelicaSimulationMethods = "dassl,euler,rungekutta,inline-euler,inline-rungekutta,dasslwort,dasslSymJac";
QString Helper::ModelicaInitializationMethods = ",none,symbolic,numeric";
QString Helper::ModelicaOptimizationMethods = ",nelder_mead_ex,nelder_mead_ex2,simplex,newuoa";
QString Helper::clockOptions = ",RT,CPU";
QString Helper::linearSolvers = ",lapack";
QString Helper::nonLinearSolvers = ",hybrid,kinsol,newton";
QString Helper::ModelicaSimulationOutputFormats = "mat,plt,csv,empty";
QString Helper::fontSizes = "6,7,8,9,10,11,12,14,16,18,20,22,24,26,28,36,48,72";
QString Helper::notificationLevel = ".OpenModelica.Scripting.ErrorLevel.notification";
QString Helper::warningLevel = ".OpenModelica.Scripting.ErrorLevel.warning";
QString Helper::errorLevel = ".OpenModelica.Scripting.ErrorLevel.error";
QString Helper::syntaxKind = ".OpenModelica.Scripting.ErrorKind.syntax";
QString Helper::grammarKind = ".OpenModelica.Scripting.ErrorKind.grammar";
QString Helper::translationKind = ".OpenModelica.Scripting.ErrorKind.translation";
QString Helper::symbolicKind = ".OpenModelica.Scripting.ErrorKind.symbolic";
QString Helper::simulationKind = ".OpenModelica.Scripting.ErrorKind.simulation";
QString Helper::scriptingKind = ".OpenModelica.Scripting.ErrorKind.scripting";
/* Global translated variables */
QString Helper::browse;
QString Helper::ok;
QString Helper::cancel;
QString Helper::error;
QString Helper::chooseFile;
QString Helper::attributes;
QString Helper::properties;
QString Helper::connection;
QString Helper::edit;
QString Helper::save;
QString Helper::importFMI;
QString Helper::chooseDirectory;
QString Helper::general;
QString Helper::parameters;
QString Helper::name;
QString Helper::comment;
QString Helper::type;
QString Helper::information;
QString Helper::modelicaFiles;
QString Helper::rename;
QString Helper::checkModel;
QString Helper::checkModelTip;
QString Helper::instantiateModel;
QString Helper::instantiateModelTip;
QString Helper::Delete;
QString Helper::copy;
QString Helper::paste;
QString Helper::loading;
QString Helper::question;
QString Helper::search;
QString Helper::simulate;
QString Helper::simulation;
QString Helper::interactiveSimulation;
QString Helper::exportToOMNotebook;
QString Helper::options;
QString Helper::libraries;
QString Helper::text;
QString Helper::penStyle;
QString Helper::brushStyle;
QString Helper::color;
QString Helper::pickColor;
QString Helper::noColor;
QString Helper::pattern;
QString Helper::thickness;
QString Helper::smooth;
QString Helper::bezierCurve;
QString Helper::solidPen;
QString Helper::dashPen;
QString Helper::dotPen;
QString Helper::dashDotPen;
QString Helper::dashDotDotPen;
QString Helper::noBrush;
QString Helper::solidBrush;
QString Helper::horizontalBrush;
QString Helper::verticalBrush;
QString Helper::crossBrush;
QString Helper::forwardBrush;
QString Helper::backwardBrush;
QString Helper::crossDiagBrush;
QString Helper::horizontalCylinderBrush;
QString Helper::verticalCylinderBrush;
QString Helper::sphereBrush;
QString Helper::remove;
QString Helper::fileLocation;
QString Helper::errorLocation;
QString Helper::textProperties;
QString Helper::readOnly;
QString Helper::writable;
QString Helper::iconView;
QString Helper::diagramView;
QString Helper::modelicaTextView;
QString Helper::documentationView;
QString Helper::modelicaLibrarySearchText;
QString Helper::left;
QString Helper::center;
QString Helper::right;

void Helper::initHelperVariables()
{
  /* Global translated variables */
  Helper::browse = tr("Browse...");
  Helper::ok = tr("OK");
  Helper::cancel = tr("Cancel");
  Helper::error = tr("Error");
  Helper::chooseFile = tr("Choose File");
  Helper::attributes = tr("Attributes");
  Helper::properties = tr("Properties");
  Helper::connection = tr("Connection");
  Helper::edit = tr("Edit");
  Helper::save = tr("Save");
  Helper::importFMI = tr("Import FMI");
  Helper::chooseDirectory = tr("Choose Directory");
  Helper::general = tr("General");
  Helper::parameters = tr("Parameters");
  Helper::name = tr("Name:");
  Helper::comment = tr("Comment:");
  Helper::type = tr("Type");
  Helper::information = tr("Information");
  Helper::modelicaFiles = tr("Modelica Files");
  Helper::rename = tr("rename");
  Helper::checkModel = tr("Check Model");
  Helper::checkModelTip = tr("Check the Modelica model");
  Helper::instantiateModel = tr("Instantiate Model");
  Helper::instantiateModelTip = tr("Instantiate/Flatten the Modelica model");
  Helper::Delete = tr("Delete");
  Helper::copy = tr("Copy");
  Helper::paste = tr("Paste");
  Helper::loading = tr("Loading");
  Helper::question = tr("Question");
  Helper::search = tr("Search");
  Helper::simulate = tr("Simulate");
  Helper::simulation = tr("Simulation");
  Helper::interactiveSimulation = tr("Interactive Simulation");
  Helper::exportToOMNotebook = tr("Export to OMNotebook");
  Helper::options = tr("Options");
  Helper::libraries = tr("Libraries");
  Helper::text = tr("Text");
  Helper::penStyle = tr("Pen Style");
  Helper::brushStyle = tr("Brush Style");
  Helper::color = tr("Color:");
  Helper::pickColor = tr("Pick Color");
  Helper::noColor = tr("No Color");
  Helper::thickness = tr("Thickness:");
  Helper::smooth = tr("Smooth:");
  Helper::bezierCurve = tr("Bezier Curve");
  Helper::solidPen = tr("Solid");
  Helper::dashPen = tr("Dash");
  Helper::dotPen = tr("Dot");
  Helper::dashDotPen = tr("Dash Dot");
  Helper::dashDotDotPen = tr("Dash Dot Dot");
  Helper::noBrush = tr("No Brush");
  Helper::solidBrush = tr("Solid");
  Helper::horizontalBrush = tr("Horizontal");
  Helper::verticalBrush = tr("Vertical");
  Helper::crossBrush = tr("Cross");
  Helper::forwardBrush = tr("Forward");
  Helper::backwardBrush = tr("Backward");
  Helper::crossDiagBrush = tr("CrossDiag");
  Helper::horizontalCylinderBrush = tr("HorizontalCylinder");
  Helper::verticalCylinderBrush = tr("VerticalCylinder");
  Helper::sphereBrush = tr("Sphere");
  Helper::remove = tr("Remove");
  Helper::fileLocation = tr("Location", "For files");
  Helper::errorLocation = tr("Location", "For errors");
  Helper::textProperties = tr("Text Properties");
  Helper::readOnly = tr("Read-Only");
  Helper::writable = tr("Writable");
  Helper::iconView = tr("Icon View");
  Helper::diagramView = tr("Diagram View");
  Helper::modelicaTextView = tr("Modelica Text View");
  Helper::documentationView = tr("View Documentation");
  Helper::modelicaLibrarySearchText = tr("Search Modelica Standard Library");
  Helper::left = tr("Left");
  Helper::center = tr("Center");
  Helper::right = tr("Right");
}

QString GUIMessages::getMessage(int type)
{
  switch (type)
  {
    case CHECK_PROBLEMS_TAB:
      return tr("Please check the Problems Tab below for more error specific details.");
    case SAME_COMPONENT_NAME:
      return tr("A Component with the same name already exists. Please choose another Name.");
    case SAME_PORT_CONNECT:
      return tr("You cannot connect a port to itself.");
    case NO_OPEN_MODEL:
      return tr("There is no open Model to %1.");
    case NO_SIMULATION_STARTTIME:
      return tr("Simulation Start Time is not defined. Default value (0.0) will be used.");
    case NO_SIMULATION_STOPTIME:
      return tr("Simulation Stop Time is not defined.");
    case SIMULATION_STARTTIME_LESSTHAN_STOPTIME:
      return tr("Simulation Start Time should be less than or equal to Stop Time.");
    case ENTER_NAME:
      return tr("Please enter %1 Name.");
    case MODEL_ALREADY_EXISTS:
      return tr("%1 %2 already exists %3.");
    case ITEM_ALREADY_EXISTS:
      return tr("An item with the same name already exists. Please try some other name.");
    case OPENMODELICAHOME_NOT_FOUND:
      return tr("Could not find environment variable OPENMODELICAHOME. Please make sure OpenModelica is installed properly.");
    case ERROR_OCCURRED:
      return tr("Following Error has occurred. \n\n%1");
    case ERROR_IN_MODELICA_TEXT:
      return tr("Problems are found in Modelica Text. \n");
    case UNDO_OR_FIX_ERRORS:
      return tr("\n\nFor normal users it is recommended to choose 'Undo changes'. You can also choose 'Let me fix errors' if you want to fix them by your own.");
    case NO_OPENMODELICA_KEYWORDS:
      return tr("Please make sure you are not using any OpenModelica Keywords like (model, package, record, class etc.)");
    case INCOMPATIBLE_CONNECTORS:
      return tr("Incompatible types for the connectors.");
    case SAVE_CHANGES:
      return tr("Do you want to save your changes before closing?");
    case DELETE_FAIL:
      return tr("Unable to delete. Server error has occurred while trying to delete.");
    case ONLY_MODEL_ALLOWED:
      return tr("This item is not a model.");
    case UNABLE_TO_LOAD_FILE:
      return tr("Error has occurred while loading the file '%1'. Unable to load the file.");
    case UNABLE_TO_LOAD_MODEL:
      return tr("Error has occurred while loading the model : \n%1.");
    case DELETE_AND_LOAD:
      return tr("Delete the existing models before loading the file.");
    case REDEFINING_EXISTING_MODELS:
      return tr("Redefining models '%1' which already exists.");
    case INVALID_COMPONENT_ANNOTATIONS:
      return tr("The Annotations for the component %1 (%2) are not correct. Unable to add component.");
    case SAVED_MODEL:
      return tr("The %1 '%2' is not saved.");
    case COMMENT_SAVE_ERROR:
      return tr("Following Error has occurred while saving component comment. \n\n %1.");
    case ATTRIBUTES_SAVE_ERROR:
      return tr("Following Error has occurred while saving component attributes. \n\n %1.");
    case CHILD_MODEL_SAVE:
      return tr("The %1 '%2' is contained inside a package. It is automatically saved when you save the package.");
    case SEARCH_STRING_NOT_FOUND:
      return tr("The search string '%1' is not found.");
    case FILE_REMOVED_MSG:
      return tr("The file '%1' has been removed outside %2. Do you want to keep it?");
    case FILE_MODIFIED_MSG:
      return tr("The file '%1' has been modified outside %2. Do you want to reload it?");
    case CLOSE_INTERACTIVE_SIMULATION_TAB:
      return tr("Are you sure you want to close '%1' interactive simulation?");
    case INFO_CLOSE_INTERACTIVE_SIMULATION_TAB:
      return tr("You cannot recover this window once it is closed.");
    case INTERACTIVE_SIMULATION_RUNNIG:
      return tr("You already have one interactive simulation running. Only one interactive simulation session is allowed at a time. \n\n Please shutdown the interactive simulation or close the interactive simulation tab before launching the new one.");
    case SELECT_VARIABLE_FOR_OMI:
      return tr("Please select a variable to plot before starting.");
    case DIAGRAM_VIEW_DROP_MSG:
      return tr("You cannot insert %1, it is a %2. Only model, class, connector, record or block are allowed on diagram layer.");
    case ICON_VIEW_DROP_MSG:
      return tr("You cannot insert %1, it is a %2. Only connector is allowed on the icon layer.");
    case PLOT_PARAMETRIC_DIFF_FILES:
      return tr("You cannot do a plot parametric between two different simulation result files. Make sure you select two variables from the same simulation result file.");
    case FILE_FORMAT_NOT_SUPPORTED:
      return tr("The file '%1' is not a valid Modelica file. The file format is not supported. You can only open .mo files here.");
    case INCORRECT_HTML_TAGS:
      return tr("The html tags in the documentation are incorrect. Give correct starting and ending html tags and save it again.");
    case ENTER_VALID_INTEGER:
      return tr("Enter a valid Positive Integer");
    case ITEM_DROPPED_ON_ITSELF:
      return tr("You cannot drop an item on itself.");
    case DELETE_PACKAGE_MSG:
      return tr("Are you sure you want to delete '%1'? Everything contained inside this Package will also be deleted.");
    case DELETE_MSG:
      return tr("Are you sure you want to delete '%1'?");
    case INNER_MODEL_NAME_CHANGED:
      return tr("A component with the name %1 already exists. The name is changed from %1 to %2.\nThis is probably wrong because the component is declared as %3.");
    case FMI_GENERATED:
      return tr("The FMI is generated at %1/%2.fmu");
    case WRONG_MODIFIER:
      return tr("The Modifier '%1' format is invalid. The correct format is 'phi(start=1)'");
    case UNKNOWN_FILE_FORMAT:
      return tr("Unknown file format. The supported file formats are %1.");
    default:
      return "";
  }
}
