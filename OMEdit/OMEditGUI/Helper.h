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

#ifndef HELPER_H
#define HELPER_H

#include <stdlib.h>
#include <QString>
#include <QSize>
#include <QObject>

class Helper : public QObject
{
  Q_OBJECT
public:
  static void initHelperVariables();
  /* Global non-translated variables */
  static QString applicationName;
  static QString applicationVersion;
  static QString applicationIntroText;
  static int settingsVersion;
  static QString OpenModelicaHome;
  static QString OpenModelicaLibrary;
  static QString OpenModelicaLibraryVersion;
  static QString omcServerName;
  static QString omFileTypes;
  static QString omnotebookFileTypes;
  static QString imageFileTypes;
  static QString fmuFileTypes;
  static QString xmlFileTypes;
  static QString matFileTypes;
  static int treeIndentation;
  static QSize iconSize;
  static QSize buttonIconSize;
  static int tabWidth;
  static qreal globalDiagramXScale;
  static qreal globalDiagramYScale;
  static qreal globalIconXScale;
  static qreal globalIconYScale;
  static qreal shapesStrokeWidth;
  static int headingFontSize;
  static QString ModelicaSimulationMethods;
  static QString ModelicaSimulationOutputFormats;
  static QString ModelicaInitializationMethods;
  static QString ModelicaOptimizationMethods;
  static QString clockOptions;
  static QString linearSolvers;
  static QString nonLinearSolvers;
  static QString fontSizes;
  static QString notificationLevel;
  static QString warningLevel;
  static QString errorLevel;
  static QString syntaxKind;
  static QString grammarKind;
  static QString translationKind;
  static QString symbolicKind;
  static QString simulationKind;
  static QString scriptingKind;
  static QString clearInfoMessages;
  /* Global translated variables */
  static QString browse;
  static QString ok;
  static QString cancel;
  static QString error;
  static QString chooseFile;
  static QString attributes;
  static QString properties;
  static QString connection;
  static QString edit;
  static QString save;
  static QString importFMI;
  static QString chooseDirectory;
  static QString general;
  static QString parameters;
  static QString name;
  static QString comment;
  static QString type;
  static QString information;
  static QString modelicaFiles;
  static QString rename;
  static QString checkModel;
  static QString checkModelTip;
  static QString instantiateModel;
  static QString instantiateModelTip;
  static QString Delete;
  static QString copy;
  static QString paste;
  static QString loading;
  static QString question;
  static QString search;
  static QString model;
  static QString Class;
  static QString connector;
  static QString record;
  static QString block;
  static QString function;
  static QString functionTip;
  static QString simulate;
  static QString simulation;
  static QString interactiveSimulation;
  static QString exportToOMNotebook;
  static QString options;
  static QString libraries;
  static QString text;
  static QString penStyle;
  static QString brushStyle;
  static QString color;
  static QString pickColor;
  static QString noColor;
  static QString pattern;
  static QString thickness;
  static QString smooth;
  static QString bezierCurve;
  static QString solidPen;
  static QString dashPen;
  static QString dotPen;
  static QString dashDotPen;
  static QString dashDotDotPen;
  static QString noBrush;
  static QString solidBrush;
  static QString horizontalBrush;
  static QString verticalBrush;
  static QString crossBrush;
  static QString forwardBrush;
  static QString backwardBrush;
  static QString crossDiagBrush;
  static QString horizontalCylinderBrush;
  static QString verticalCylinderBrush;
  static QString sphereBrush;
  static QString remove;
  static QString errorLocation;
  static QString fileLocation;
  static QString textProperties;
  static QString readOnly;
  static QString writable;
  static QString iconView;
  static QString diagramView;
  static QString modelicaTextView;
  static QString documentationView;
  static QString modelicaLibrarySearchText;
  static QString left;
  static QString center;
  static QString right;
};

class GUIMessages : public QObject
{
  Q_OBJECT
public:
  enum MessagesTypes
  {
    CHECK_PROBLEMS_TAB,
    SAME_COMPONENT_NAME,
    SAME_PORT_CONNECT,
    NO_OPEN_MODEL,
    NO_SIMULATION_STARTTIME,
    NO_SIMULATION_STOPTIME,
    SIMULATION_STARTTIME_LESSTHAN_STOPTIME,
    ENTER_NAME,
    MODEL_ALREADY_EXISTS,
    ITEM_ALREADY_EXISTS,
    OPENMODELICAHOME_NOT_FOUND,
    ERROR_OCCURRED,
    ERROR_IN_MODELICA_TEXT,
    UNDO_OR_FIX_ERRORS,
    NO_OPENMODELICA_KEYWORDS,
    INCOMPATIBLE_CONNECTORS,
    SAVE_CHANGES,
    DELETE_FAIL,
    ONLY_MODEL_ALLOWED,
    UNABLE_TO_LOAD_FILE,
    UNABLE_TO_LOAD_MODEL,
    DELETE_AND_LOAD,
    REDEFINING_EXISTING_MODELS,
    INVALID_COMPONENT_ANNOTATIONS,
    SAVED_MODEL,
    COMMENT_SAVE_ERROR,
    ATTRIBUTES_SAVE_ERROR,
    CHILD_MODEL_SAVE,
    SEARCH_STRING_NOT_FOUND,
    FILE_REMOVED_MSG,
    FILE_MODIFIED_MSG,
    CLOSE_INTERACTIVE_SIMULATION_TAB,
    INFO_CLOSE_INTERACTIVE_SIMULATION_TAB,
    INTERACTIVE_SIMULATION_RUNNIG,
    SELECT_VARIABLE_FOR_OMI,
    DIAGRAM_VIEW_DROP_MSG,
    ICON_VIEW_DROP_MSG,
    PLOT_PARAMETRIC_DIFF_FILES,
    INCORRECT_HTML_TAGS,
    FILE_FORMAT_NOT_SUPPORTED,
    ENTER_VALID_INTEGER,
    ITEM_DROPPED_ON_ITSELF,
    DELETE_PACKAGE_MSG,
    DELETE_MSG,
    INNER_MODEL_NAME_CHANGED,
    FMI_GENERATED,
    WRONG_MODIFIER,
    UNKNOWN_FILE_FORMAT
  };

  static QString getMessage(int type);
};

#endif // HELPER_H
