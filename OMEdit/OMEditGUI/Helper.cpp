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

#include "Helper.h"

QString Helper::applicationName = "OMEdit";
QString Helper::applicationVersion = "Version: 1.8.1";
QString Helper::applicationIntroText = "OpenModelica Connection Editor";
/* Increment this settings number if you change something in the QMainWindow appereance
 * Otherwise OMEdit will load the old settings and Qt make a mess of your toolbars and dockwidgets.
 */
int Helper::settingsVersion = 0;
// these two variables are set once we are connected to OMC......in OMCProxy::startServer().
QString Helper::OpenModelicaHome = QString();
QString Helper::OpenModelicaLibrary = QString();
QString Helper::omcServerName = "OMEdit";
QString Helper::omFileTypes = "Modelica Files (*.mo)";
QString Helper::omnotebookFileTypes = "OMNotebook Files (*.onb *.onbz *.nb)";
QString Helper::imageFileTypes = "Image Files (*.png *.svg *.bmp *.jpg)";
QString Helper::fmuFileTypes = "FMU Files (*.fmu)";
QString Helper::xmlFileTypes = "XML Files (*.xml)";
QString Helper::matFileTypes = "MAT Files (*.mat)";
QString Helper::readOnly = QString("Read-Only");
QString Helper::writeAble = QString("Writeable");
QString Helper::iconView = QString("Icon View");
QString Helper::diagramView = QString("Diagram View");
QString Helper::modelicaTextView = QString("Modelica Text View");
QString Helper::documentationView = QString("View Documentation");
int Helper::viewWidth = 2000;
int Helper::viewHeight = 2000;
qreal Helper::globalDiagramXScale = 1.0;
qreal Helper::globalDiagramYScale = 1.0;
qreal Helper::globalIconXScale = 0.12;
qreal Helper::globalIconYScale = 0.12;
int Helper::treeIndentation = 13;
QSize Helper::iconSize = QSize(20, 20);
QSize Helper::buttonIconSize = QSize(20, 20);
int Helper::headingFontSize = 18;
int Helper::tabWidth = 20;
qreal Helper::shapesStrokeWidth = 5.0;
QString Helper::modelicaLibrarySearchText = QString("Search Modelica Standard Library");
QString Helper::noItemFound = QString("Sorry, no items found");
/* Interactive Simulation Messages */
QString Helper::compiling_Model = QString("Compiling Model");
QString Helper::compiling_Model_text = QString("Compiling Model.\nPlease wait for a while.");
QString Helper::running_Simulation = QString("Running Simulation");
QString Helper::running_Simulation_text = QString("Running Simulation.\nPlease wait for a while.");
QString Helper::starting_interactive_simulation_server = QString("Starting Interactive Simulation Server");
QString Helper::omi_network_address = QString("127.0.0.1");
quint16 Helper::omi_control_client_port = 10501;
quint16 Helper::omi_control_server_port = 10500;
quint16 Helper::omi_transfer_server_port = 10502;
QString Helper::omi_initialize_button_tooltip = QString("Initializes the interactive simulation.");
QString Helper::omi_start_button_tooltip = QString("Starts or continues the interactive simulation.");
QString Helper::omi_pause_button_tooltip = QString("Pauses the running interactive simulation.");
QString Helper::omi_stop_button_tooltip = QString("Stops the running interactive simulation and resets all values to the beginning.");
QString Helper::omi_shutdown_button_tooltip = QString("Shut down the running interactive simulation.");
QString Helper::omi_showlog_button_tooltip = QString("Shows the OMI Log Message Window.");
// pen styles with icons
QString Helper::solidPenIcon = QString(":/Resources/icons/solidline.png");
QString Helper::solidPen = QString("Solid");
Qt::PenStyle Helper::solidPenStyle = Qt::SolidLine;
QString Helper::dashPenIcon = QString(":/Resources/icons/dashline.png");
QString Helper::dashPen = QString("Dash");
Qt::PenStyle Helper::dashPenStyle = Qt::DashLine;
QString Helper::dotPenIcon = QString(":/Resources/icons/dotline.png");
QString Helper::dotPen = QString("Dot");
Qt::PenStyle Helper::dotPenStyle = Qt::DotLine;
QString Helper::dashDotPenIcon = QString(":/Resources/icons/dashdotline.png");
QString Helper::dashDotPen = QString("Dash Dot");
Qt::PenStyle Helper::dashDotPenStyle = Qt::DashDotLine;
QString Helper::dashDotDotPenIcon = QString(":/Resources/icons/dashdotdotline.png");
QString Helper::dashDotDotPen = QString("Dash Dot Dot");
Qt::PenStyle Helper::dashDotDotPenStyle = Qt::DashDotDotLine;
// brush styles with icons
QString Helper::solidBrushIcon = QString(":/Resources/icons/solid.png");
QString Helper::solidBrush = QString("Solid");
Qt::BrushStyle Helper::solidBrushStyle = Qt::SolidPattern;
QString Helper::horizontalBrushIcon = QString(":/Resources/icons/horizontal.png");
QString Helper::horizontalBrush = QString("Horizontal");
Qt::BrushStyle Helper::horizontalBrushStyle = Qt::HorPattern;
QString Helper::verticalBrushIcon = QString(":/Resources/icons/vertical.png");
QString Helper::verticalBrush = QString("Vertical");
Qt::BrushStyle Helper::verticalBrushStyle = Qt::VerPattern;
QString Helper::crossBrushIcon = QString(":/Resources/icons/cross.png");
QString Helper::crossBrush = QString("Cross");
Qt::BrushStyle Helper::crossBrushStyle = Qt::CrossPattern;
QString Helper::forwardBrushIcon = QString(":/Resources/icons/forward.png");
QString Helper::forwardBrush = QString("Forward");
Qt::BrushStyle Helper::forwardBrushStyle = Qt::CrossPattern;
QString Helper::backwardBrushIcon = QString(":/Resources/icons/backward.png");
QString Helper::backwardBrush = QString("Backward");
Qt::BrushStyle Helper::backwardBrushStyle = Qt::CrossPattern;
QString Helper::crossDiagBrushIcon = QString(":/Resources/icons/crossdiag.png");
QString Helper::crossDiagBrush = QString("CrossDiag");
Qt::BrushStyle Helper::crossDiagBrushStyle = Qt::DiagCrossPattern;
QString Helper::horizontalCylinderBrushIcon = QString(":/Resources/icons/horizontalcylinder.png");
QString Helper::horizontalCylinderBrush = QString("HorizontalCylinder");
Qt::BrushStyle Helper::horizontalCylinderBrushStyle = Qt::LinearGradientPattern;
QString Helper::verticalCylinderBrushIcon = QString(":/Resources/icons/verticalcylinder.png");
QString Helper::verticalCylinderBrush = QString("VertitalCylinder");
Qt::BrushStyle Helper::verticalCylinderBrushStyle = Qt::Dense1Pattern;
QString Helper::sphereBrushIcon = QString(":/Resources/icons/sphere.png");
QString Helper::sphereBrush = QString("Sphere");
Qt::BrushStyle Helper::sphereBrushStyle = Qt::RadialGradientPattern;
/* Export Image and Notebook Messages */
QString Helper::exportAsImage = QString("Exporting model as an Image");
QString Helper::exportToOMNotebook = QString("Exporting model to OMNotebook");
QString Helper::importFromOMNotebook = QString("Importing model from OMNotebook");
/* Simulation Messages */
QString Helper::ModelicaSimulationMethods = "dassl,dassl2,euler,rungekutta,dopri5,inline-euler,inline-rungekutta";
QString Helper::ModelicaInitializationMethods = "none,state";
QString Helper::ModelicaOptimizationMethods = "nelder_mead_ex,nelder_mead_ex2,simplex,newuoa";
QString Helper::ModelicaSimulationOutputFormats = "mat,plt,csv,empty";

QString Helper::fontSizes = QString("6,7,8,9,10,11,12,14,16,18,20,22,24,26,28,36,48,72");

QString Helper::left = QString("Left");
QString Helper::center = QString("Center");
QString Helper::right = QString("Right");
/* FMI Messages */
QString Helper::exportingModelFMU = QString("Exporting model as FMI");
QString Helper::import = QString("Import");
QString Helper::importFMI = QString("Import FMI");
QString Helper::fmuFileName = QString("FMU File:");
QString Helper::browse = QString("Browse...");
QString Helper::outputDirectory = QString("Output Directory (Optional):");
QString Helper::outputDirectoryNote = QString("* If no Output Directory specified then the FMU files are generated in the current working directory.");

QString Helper::librariesAddNote = QString("* The libraries changes will take effect after restart.");

QString Helper::modifiersLabelText = QString("Add new modifiers, e.g phi(start=1),w(start=2)");

QString Helper::saveContentsOneFile = QString("Save contents of package in one file");
/* OpenModelica Error types and kinds */
QString Helper::notificationLevel = QString(".OpenModelica.Scripting.ErrorLevel.notification");
QString Helper::warningLevel = QString(".OpenModelica.Scripting.ErrorLevel.warning");
QString Helper::errorLevel = QString(".OpenModelica.Scripting.ErrorLevel.error");
QString Helper::syntaxKind = QString(".OpenModelica.Scripting.ErrorKind.syntax");
QString Helper::grammarKind = QString(".OpenModelica.Scripting.ErrorKind.grammar");
QString Helper::translationKind = QString(".OpenModelica.Scripting.ErrorKind.translation");
QString Helper::symbolicKind = QString(".OpenModelica.Scripting.ErrorKind.symbolic");
QString Helper::simulationKind = QString(".OpenModelica.Scripting.ErrorKind.simulation");
QString Helper::scriptingKind = QString(".OpenModelica.Scripting.ErrorKind.scripting");
/* MessageCornerWidget Messages */
QString Helper::clearProblems = QString("Clear All Problems");
QString Helper::clearMessages = QString("Clear All General Messages");
QString Helper::showNotifications = QString("Only Show Notifications");
QString Helper::showWarnings = QString("Only Show Warnings");
QString Helper::showErrors = QString("Only Show Errors");
QString Helper::showAllProblems = QString("Show All Problems");

QString GUIMessages::getMessage(int type)
{
    switch (type)
    {
        case CHECK_PROBLEMS_TAB:
            return "Please check the Problems Tab below for more error specific details.";
        case SAME_COMPONENT_NAME:
            return "A Component with the same name already exists. Please choose another Name.";
        case SAME_PORT_CONNECT:
            return "You cannot connect a port to itself.";
        case NO_OPEN_MODEL:
            return "There is no open Model to %1.";
        case NO_SIMULATION_STARTTIME:
            return "Simulation Start Time is not defined. Default value (0.0) will be used.";
        case NO_SIMULATION_STOPTIME:
            return "Simulation Stop Time is not defined.";
        case SIMULATION_STARTTIME_LESSTHAN_STOPTIME:
            return "Simulation Start Time should be less than or equal to Stop Time.";
        case ENTER_NAME:
            return "Please enter %1 Name.";
        case MODEL_ALREADY_EXISTS:
            return "%1 %2 already exits %3.";
        case ITEM_ALREADY_EXISTS:
            return "An item with the same name already exists. Please try some other name.";
        case OPEN_MODELICA_HOME_NOT_FOUND:
            return "Could not find environment variable OPENMODELICAHOME. Please make sure OpenModelica is installed properly.";
        case ERROR_OCCURRED:
            return "Following Error has occurred. \n\n%1";
        case ERROR_IN_MODELICA_TEXT:
            return "Problems are found in Modelica Text. \n";
        case UNDO_OR_FIX_ERRORS:
            return "\n\nFor normal users it is recommended to choose 'Undo changes'. You can also choose 'Let me fix errors' if you want to fix them by your own.";
        case NO_OPEN_MODELICA_KEYWORDS:
            return "Please make sure you are not using any OpenModelica Keywords like (model, package, record, class etc.)";
        case INCOMPATIBLE_CONNECTORS:
            return "Incompatible types for the connectors.";
        case SAVE_CHANGES:
            return "Do you want to save your changes before closing?";
        case DELETE_FAIL:
            return "Unable to delete. Server error has occurred while trying to delete.";
        case ONLY_MODEL_ALLOWED:
            return "This item is not a model.";
        case UNABLE_TO_LOAD_FILE:
            return "Error has occurred while loading the file '%1'. Unable to load the file.";
        case UNABLE_TO_LOAD_MODEL:
            return "Error has occurred while loading the model : \n%1.";
        case DELETE_AND_LOAD:
            return "Delete the existing models before loading the file.";
        case REDEFING_EXISTING_MODELS:
            return "Redefing models '%1' which already exists.";
        case INVALID_COMPONENT_ANNOTATIONS:
            return "The Annotations for the component %1 (%2) are not correct. Unable to add component.";
        case SAVED_MODEL:
            return "The %1 '%2' is not saved.";
        case COMMENT_SAVE_ERROR:
            return "Following Error has occurred while saving component comment. \n\n %1.";
        case ATTRIBUTES_SAVE_ERROR:
            return "Following Error has occurred while saving component attributes. \n\n %1.";
        case CHILD_MODEL_SAVE:
            return "The %1 '%2' is contained inside a package. It is automatically saved when you save the package.";
        case SEARCH_STRING_NOT_FOUND:
            return "The search string '%1' is not found.";
        case FILE_REMOVED_MSG:
            return "The file '%1' has been removed outside %2. Do you want to keep it?";
        case FILE_MODIFIED_MSG:
            return "The file '%1' has been modified outside %2. Do you want to reload it?";
        case CLOSE_INTERACTIVE_SIMULATION_TAB:
            return "Are you sure you want to close '%1' interactive simulation?";
        case INFO_CLOSE_INTERACTIVE_SIMULATION_TAB:
            return "You cannot recover this window once its closed.";
        case INTERACTIVE_SIMULATION_RUNNIG:
            return "You already have one interactive simulation running. Only one interactive simulaiton session is allowed at a time. \n\n Please shutdown the interactive simulation or close the interactive simulation tab before launching the new one.";
        case SELECT_VARIABLE_FOR_OMI:
            return "Please select a variable to plot before starting.";
        case DIAGRAM_VIEW_DROP_MSG:
            return "You cannot insert %1, it is a %2. Only model, class, connector, record or block are allowed on diagram layer.";
        case ICON_VIEW_DROP_MSG:
            return "You cannot insert %1, it is a %2. Only connector is allowed on the icon layer.";
        case PLOT_PARAMETRIC_DIFF_FILES:
            return "You cannot do a plot parametric between two different simulation result files. Make sure you select two variables from the same simulation result file.";
        case FILE_FORMAT_NOT_SUPPORTED:
            return "The file '%1' is not a valid Modelica file. The file format is not supported. You can only open .mo files here.";
        case INCORRECT_HTML_TAGS:
            return "The html tags in the documentation are incorrect. Give correct starting and ending html tags and save it again.";
        case ENTER_VALID_INTEGER:
            return "Enter a valid Positive Integer";
        case ITEM_DROPPED_ON_ITSELF:
            return "You cannot drop an item on itself.";
        case DELETE_PACKAGE_MSG:
            return "Are you sure you want to delete '%1'? Everything contained inside this Package will also be deleted.";
        case DELETE_MSG:
            return "Are you sure you want to delete '%1'?";
        case INNER_MODEL_NAME_CHANGED:
            return "A component with the name %1 already exists. The name is changed from %1 to %2.\nThis is probably wrong because the component is decalred as %3.";
        case FMI_GENERATED:
            return "The FMI is generated at %1/%2.fmu";
        case WRONG_MODIFIER:
            return "The Modifier '%1' format is invalid. The correct format is 'phi(start=1)'";
        default:
            return "";
    }
}
