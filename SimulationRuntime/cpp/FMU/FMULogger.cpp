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

void FMULogger::writeInternal(std::string errorMsg, LogCategory cat, LogLevel lvl)
{
  switch(lvl)
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
