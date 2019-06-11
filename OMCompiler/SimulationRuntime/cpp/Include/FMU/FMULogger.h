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
