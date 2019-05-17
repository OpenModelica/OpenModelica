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
FMULogger::FMULogger(fmiCallbackLogger callbackLogger, fmiComponent component, fmiString instanceName) : Logger(LogSettings(LF_FMI), false),
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
