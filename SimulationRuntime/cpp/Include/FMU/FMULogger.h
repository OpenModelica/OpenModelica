/*
 * FMULogger.h
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */

#ifndef FMULOGGER_H_
#define FMULOGGER_H_

#include <Core/Utils/extension/logger.hpp>
#include "fmiModelFunctions.h"

class FMULogger : Logger
{
  public:
    FMULogger(fmiCallbackLogger callbackLogger, fmiComponent component, fmiString instanceName);
    virtual ~FMULogger();

    static void initialize(fmiCallbackLogger callbackLogger, fmiComponent component, fmiString instanceName)
    {
      if(instance != NULL)
        delete instance;

      instance = new FMULogger(callbackLogger, component, instanceName);
    }

  protected:
    virtual void writeErrorInternal(std::string errorMsg);
    virtual void writeWarningInternal(std::string warningMsg);
    virtual void writeInfoInternal(std::string infoMsg);

  private:
    fmiCallbackLogger callbackLogger;
    fmiComponent component;
    fmiString instanceName;
};

#endif /* FMULOGGER_H_ */
