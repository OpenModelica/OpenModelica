/*
 * FMULogger.cpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <FMU/FMULogger.h>

#if defined(_MSC_VER) && !defined(RUNTIME_STATIC_LINKING)
	Logger* Logger::instance = 0;
#endif

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
