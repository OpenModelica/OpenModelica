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
 * FMULogger.h
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */

#ifndef FMULOGGER_H_
#define FMULOGGER_H_

#include <Core/Modelica.h>

//#include <Core/Utils/extension/logger.hpp>
#include "fmiModelFunctions.h"

class BOOST_EXTENSION_EXPORT_DECL FMULogger : Logger
{
  public:
    FMULogger(fmiCallbackLogger callbackLogger, fmiComponent component, fmiString instanceName);
    virtual ~FMULogger();

    static void initialize(fmiCallbackLogger callbackLogger, fmiComponent component, fmiString instanceName)
    {
      _instance = new FMULogger(callbackLogger, component, instanceName);
    }

  protected:
    virtual void writeInternal(std::string errorMsg, LogCategory cat, LogLevel lvl, LogStructure ls);
  private:
    fmiCallbackLogger callbackLogger;
    fmiComponent component;
    fmiString instanceName;
};

#endif /* FMULOGGER_H_ */
