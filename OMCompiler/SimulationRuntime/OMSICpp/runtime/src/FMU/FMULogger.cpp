/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/*
 * FMULogger.cpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <FMU/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <FMU/FMULogger.h>

/*
#if defined(_MSC_VER) && !defined(RUNTIME_STATIC_LINKING)
    Logger* Logger::_instance = 0;
#endif
*/
FMULogger::FMULogger(fmiCallbackLogger callbackLogger, fmiComponent component, fmiString instanceName) :
    Logger(LogSettings(LF_FMI), false),
    callbackLogger(callbackLogger), component(component), instanceName(instanceName)
{
}

FMULogger::~FMULogger()
{
}

void FMULogger::writeInternal(std::string errorMsg, LogCategory cat, LogLevel lvl, LogStructure ls)
{
    if (ls == LS_END)
        return;

    switch (lvl)
    {
    case(LL_ERROR):
        callbackLogger(component, instanceName, fmiError, "?", errorMsg.c_str());
        break;
    case(LL_WARNING):
        callbackLogger(component, instanceName, fmiWarning, "?", errorMsg.c_str());
        break;
    case(LL_INFO):
    case(LL_DEBUG):
        callbackLogger(component, instanceName, fmiOK, "?", errorMsg.c_str());
        break;
    default:
        callbackLogger(component, instanceName, fmiError, "?", errorMsg.c_str());
    }
}
