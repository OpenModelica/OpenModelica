/**
 *  \file osi.cpp
 *  \brief Brief
 */


//Cpp Simulation kernel includes
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>
#include <omsi_global_settings.h>
#include "omsi_fmi2_log.h"
#include "omsi_fmi2_wrapper.h"

FMU2Logger::FMU2Logger(OSU *wrapper,
                       LogSettings &logSettings, bool enabled) :
  Logger(logSettings, enabled),
  _wrapper(wrapper)
{
}

void FMU2Logger::initialize(OSU *wrapper, LogSettings &logSettings, bool enabled)
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
  switch (lvl) {
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
  switch (cat) {
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