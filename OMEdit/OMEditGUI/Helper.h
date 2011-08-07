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

#ifndef HELPER_H
#define HELPER_H

#include <stdlib.h>
#include <QString>
#include <QSize>

class Helper
{
public:
    static QString applicationName;
    static QString applicationVersion;
    static QString applicationIntroText;
    static QString OpenModelicaHome;
    static QString OpenModelicaLibrary;
    static QString omcServerName;
    static QString omFileTypes;
    static QString omnotebookFileTypes;
    static QString imageFileTypes;
    static QString tmpPath;
    static QString readOnly;
    static QString writeAble;
    static QString iconView;
    static QString diagramView;
    static QString modelicaTextView;
    static QString documentationView;
    static int viewWidth;
    static int viewHeight;
    static qreal globalDiagramXScale;
    static qreal globalDiagramYScale;
    static qreal globalIconXScale;
    static qreal globalIconYScale;
    static QString ModelicaSimulationMethods;
    static QString ModelicaSimulationOutputFormats;
    static int treeIndentation;
    static QSize iconSize;
    static QSize buttonIconSize;
    static int headingFontSize;
    static int tabWidth;
    static qreal shapesStrokeWidth;
    static QString modelicaLibrarySearchText;
    static QString noItemFound;
    static QString running_Simulation;
    static QString running_Simulation_text;
    static QString starting_interactive_simulation_server;
    static QString omi_network_address;
    static quint16 omi_control_client_port;
    static quint16 omi_control_server_port;
    static quint16 omi_transfer_server_port;
    static QString omi_initialize_button_tooltip;
    static QString omi_start_button_tooltip;
    static QString omi_pause_button_tooltip;
    static QString omi_stop_button_tooltip;
    static QString omi_shutdown_button_tooltip;
    static QString omi_showlog_button_tooltip;
    // pen styles with icons
    static QString solidPenIcon;
    static QString solidPen;
    static Qt::PenStyle solidPenStyle;
    static QString dashPenIcon;
    static QString dashPen;
    static Qt::PenStyle dashPenStyle;
    static QString dotPenIcon;
    static QString dotPen;
    static Qt::PenStyle dotPenStyle;
    static QString dashDotPenIcon;
    static QString dashDotPen;
    static Qt::PenStyle dashDotPenStyle;
    static QString dashDotDotPenIcon;
    static QString dashDotDotPen;
    static Qt::PenStyle dashDotDotPenStyle;
    // brush styles with icons
    static QString solidBrushIcon;
    static QString solidBrush;
    static Qt::BrushStyle solidBrushStyle;
    static QString horizontalBrushIcon;
    static QString horizontalBrush;
    static Qt::BrushStyle horizontalBrushStyle;
    static QString verticalBrushIcon;
    static QString verticalBrush;
    static Qt::BrushStyle verticalBrushStyle;
    static QString crossBrushIcon;
    static QString crossBrush;
    static Qt::BrushStyle crossBrushStyle;
    static QString forwardBrushIcon;
    static QString forwardBrush;
    static Qt::BrushStyle forwardBrushStyle;
    static QString backwardBrushIcon;
    static QString backwardBrush;
    static Qt::BrushStyle backwardBrushStyle;
    static QString crossDiagBrushIcon;
    static QString crossDiagBrush;
    static Qt::BrushStyle crossDiagBrushStyle;
    static QString horizontalCylinderBrushIcon;
    static QString horizontalCylinderBrush;
    static Qt::BrushStyle horizontalCylinderBrushStyle;
    static QString verticalCylinderBrushIcon;
    static QString verticalCylinderBrush;
    static Qt::BrushStyle verticalCylinderBrushStyle;
    static QString sphereBrushIcon;
    static QString sphereBrush;
    static Qt::BrushStyle sphereBrushStyle;
    // export import
    static QString exportAsImage;
    static QString exportToOMNotebook;
    static QString importFromOMNotebook;
};

class GUIMessages
{
public:
    enum MessagesTypes
    {
        SAME_COMPONENT_NAME,
        SAME_PORT_CONNECT,
        NO_OPEN_MODEL,
        NO_SIMULATION_STARTTIME,
        NO_SIMULATION_STOPTIME,
        SIMULATION_STARTTIME_LESSTHAN_STOPTIME,
        ENTER_NAME,
        MODEL_ALREADY_EXISTS,
        ITEM_ALREADY_EXISTS,
        OPEN_MODELICA_HOME_NOT_FOUND,
        ERROR_OCCURRED,
        ERROR_IN_MODELICA_TEXT,
        UNDO_OR_FIX_ERRORS,
        NO_OPEN_MODELICA_KEYWORDS,
        INCOMPATIBLE_CONNECTORS,
        SAVE_CHANGES,
        DELETE_FAIL,
        ONLY_MODEL_ALLOWED,
        UNABLE_TO_LOAD_FILE,
        UNABLE_TO_LOAD_MODEL,
        DELETE_AND_LOAD,
        REDEFING_EXISTING_MODELS,
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
        DELETE_MSG
    };

    static QString getMessage(int type);
};

#endif // HELPER_H
