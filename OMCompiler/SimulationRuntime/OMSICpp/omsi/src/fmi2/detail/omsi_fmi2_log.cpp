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

/**
 *  \file osi.cpp
 *  \brief Brief
 */


//Cpp Simulation kernel includes
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/IOMSI.h>
#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <omsi_global_settings.h>
#include "omsi_fmi2_log.h"
#include "omsi_fmi2_wrapper.h"

FMU2Logger::FMU2Logger(OSU* wrapper,
                       LogSettings& logSettings, bool enabled) :
    Logger(logSettings, enabled),
    _wrapper(wrapper)
{
}

void FMU2Logger::initialize(OSU* wrapper, LogSettings& logSettings, bool enabled)
{
    _instance = new FMU2Logger(wrapper, logSettings, enabled);
}

void FMU2Logger::writeInternal(string msg, LogCategory cat, LogLevel lvl,
                               LogStructure ls)
{
    LogCategoryFMU category;
    fmi2Status status;

    if (ls == LS_END)
        return;

    // determine FMI status and category from LogLevel
    switch (lvl)
    {
    case LL_ERROR:
        status = fmi2Error;
        category = logStatusError;
        break;
    case LL_WARNING:
        status = fmi2Warning;
        category = logStatusWarning;
        break;
    default:
        status = fmi2OK;
        category = logStatusWarning;
    }

    // override FMU category with matching LogCategory
    switch (cat)
    {
    case LC_NLS:
        category = logNonlinearSystems;
        break;
    case LC_EVENTS:
        category = logEvents;
        break;
    }

    // call FMU log function
    FMU2_LOG(_wrapper, status, category, msg.c_str());
}
