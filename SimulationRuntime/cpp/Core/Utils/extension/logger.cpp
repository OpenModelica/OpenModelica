/*
 * logger.cpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/extension/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>

Logger* Logger::instance = NULL;

Logger::Logger(LogSettings settings, bool enabled) : _settings(settings), _isEnabled(enabled)
{
}

Logger::Logger(bool enabled) : _settings(LogSettings()), _isEnabled(enabled)
{
}

Logger::~Logger()
{
}

void Logger::writeInternal(std::string msg, LogCategory cat, LogLevel lvl)
{
	if(isOutput(cat, lvl))
	{
		std::cerr << getPrefix(cat,lvl) << msg << std::endl;
	}
}

void Logger::setEnabledInternal(bool enabled)
{
  _isEnabled = enabled;
}

bool Logger::isEnabledInternal()
{
  return _isEnabled;
}

bool Logger::isOutput(LogCategory cat, LogLevel lvl) const
{
	return _settings.modes[cat] >= lvl && _isEnabled;
}

bool Logger::isOutput(std::pair<LogCategory,LogLevel> mode) const
{
	return isOutput(mode.first, mode.second);
}


std::string Logger::getPrefix(LogCategory cat, LogLevel lvl) const
{
	switch(lvl)
	{
	case(LL_DEBUG):
		return "DEBUG: ";
	case(LL_ERROR):
		return "ERROR: ";
	case(LL_INFO):
		return "INFO: ";
	case(LL_WARNING):
		return "WARNING: ";
	default:
		return "";

	}
}
