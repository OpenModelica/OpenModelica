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
 *
 */

#include "Helper.h"

QString Helper::applicationName = "OMEdit";
QString Helper::applicationVersion = "0.0.1";
QString Helper::applicationIntroText = "Open Modelica Connection Editor";
QString Helper::omcServerName = "OMEditor";
QString Helper::omFileTypes = "*.mo";
QString Helper::omFileOpenText = "Modelica Files (*.mo)";
qreal Helper::globalXScale = 0.15;
qreal Helper::globalYScale = 0.15;

QString Helper::ModelicaSimulationMethods = "DASSL,DASSL2,Euler,Runge-Kutta";

QString GUIMessages::getMessage(int type)
{
    if (type == SAME_COMPONENT_NAME)
        return "A Component with the same name already exists. Please choose another Name.";
    else if (type == SAME_PORT_CONNECT)
        return "You can not connect a port to itself.";
    else if (type == NO_OPEN_MODEL)
        return "There is no open Model to simulate.";
    else if (type == NO_SIMULATION_STARTTIME)
        return "Simulation Start Time is not defined. Default value (0) will be used.";
    else if (type == NO_SIMULATION_STOPTIME)
        return "Simulation Stop Time is not defined.";
    else if (type == SIMULATION_STARTTIME_LESSTHAN_STOPTIME)
        return "Simulation Start Time should be less than Stop Time.";
    else if (type == ENTER_PACKAGE_NAME)
        return "Please enter Package Name.";
    else if (type == ENTER_MODEL_NAME)
        return "Please enter Model Name.";
    else if (type == OPEN_MODELICA_HOME_NOT_FOUND)
        return "Could not find environment variable OPENMODELICAHOME. Please make sure OpenModelica is installed properly.";
    else if (type == ERROR_OCCURRED)
        return "Following Error has occurred.";
    else if (type == NO_OPEN_MODELICA_KEYWORDS)
        return "Please make sure you are not using any Open Modelica Keywords like (model, package, record, class etc.)";
    else if (type == INCOMPATIBLE_CONNECTORS)
        return "Incompatible types for the connectors.";
    else if (type == SAVE_CHANGES)
        return "Do you want to save your changes before closing?";
    else if (type == DELETE_FAIL)
        return "Unable to delete. Server error has occurred while trying to delete.";
    else if (type == ONLY_MODEL_ALLOWED)
        return "This item is not a model.";
}
