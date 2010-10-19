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

#ifndef HELPER_H
#define HELPER_H

#include <QString>

class Helper
{
public:
    static QString applicationName;
    static QString applicationVersion;
    static QString applicationIntroText;
    static QString omcServerName;
    static QString omFileTypes;
    static QString omFileOpenText;
    static qreal globalXScale;
    static qreal globalYScale;
    static QString ModelicaSimulationMethods;
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
        ENTER_PACKAGE_NAME,
        ENTER_MODEL_NAME,
        OPEN_MODELICA_HOME_NOT_FOUND,
        ERROR_OCCURRED,
        NO_OPEN_MODELICA_KEYWORDS,
        INCOMPATIBLE_CONNECTORS,
        SAVE_CHANGES,
        DELETE_FAIL,
        ONLY_MODEL_ALLOWED
    };

    static QString getMessage(int type);
};

#endif // HELPER_H
