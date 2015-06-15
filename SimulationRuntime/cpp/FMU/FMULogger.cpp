/*
 * FMULogger.cpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */

#include <FMU/FMULogger.h>

FMULogger::FMULogger(fmiCallbackLogger callbackLogger, fmiComponent component, fmiString instanceName) : Logger(false),
  callbackLogger(callbackLogger), component(component), instanceName(instanceName)
{
}

FMULogger::~FMULogger()
{
}

void FMULogger::writeErrorInternal(std::string errorMsg)
{
  callbackLogger(component, instanceName, fmiError, "?", errorMsg.c_str());
}

void FMULogger::writeWarningInternal(std::string warningMsg)
{
  callbackLogger(component, instanceName, fmiWarning, "?", warningMsg.c_str());
}

void FMULogger::writeInfoInternal(std::string infoMsg)
{
  if(isEnabledInternal())
    callbackLogger(component, instanceName, fmiOK, "?", infoMsg.c_str());
}
