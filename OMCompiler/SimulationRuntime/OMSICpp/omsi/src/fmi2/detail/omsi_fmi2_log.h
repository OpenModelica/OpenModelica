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

#ifndef OIS_LOG_H
#define OIS_LOG_H

#include "fmi2Functions.h"


#define LOG_CALL(w, ...) \
  FMU2_LOG(w, fmi2OK, logFmi2Call, __VA_ARGS__)

#define CATCH_EXCEPTION(w) \
  catch (std::exception &e) { \
    FMU2_LOG(w, fmi2Error, logStatusError, e.what()); \
    return fmi2Error; \
  }


// define logger as macro that passes through variadic args
#define FMU2_LOG(w, status, category, ...) \
  if ((w)->logCategories() & (1 << (category))) \
    (w)->callbackLogger((w)->componentEnvironment(), (w)->instanceName(), \
                        status, (w)->LogCategoryFMUName(category), __VA_ARGS__)

enum LogCategoryFMU
{
    logEvents = 0,
    logSingularLinearSystems,
    logNonlinearSystems,
    logDynamicStateSelection,
    logStatusWarning,
    logStatusDiscard,
    logStatusError,
    logStatusFatal,
    logStatusPending,
    logFmi2Call
};


/**
 * Forward Logger messages to FMI callback function
 */
class OSU;

class FMU2Logger : public Logger
{
public:
    static void initialize(OSU* wrapper, LogSettings& logSettings, bool enabled);

protected:
    FMU2Logger(OSU* wrapper, LogSettings& logSettings, bool enabled);

    virtual void writeInternal(string msg, LogCategory cat, LogLevel lvl,
                               LogStructure ls);
    OSU* _wrapper;
};


#endif
