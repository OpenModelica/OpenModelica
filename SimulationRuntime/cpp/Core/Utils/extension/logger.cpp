/*
 * logger.cpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus and rfranke
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

void Logger::initialize(LogSettings settings)
{
  if (instance != NULL)
    delete instance;

  switch (settings.format) {
  case LF_XML:
    instance = new LoggerXML(settings, true);
    break;
  default:
    instance = new Logger(settings, true);
  }
}

void Logger::writeInternal(std::string msg, LogCategory cat, LogLevel lvl,
                           LogStructure ls)
{
  if (ls != LS_END) {
    std::string catStr = getCategory(cat);
    std::ostream &stream = lvl <= 1? std::cerr: std::cout;
    stream << getPrefix(cat, lvl) << catStr.append(6 - catStr.length(), ' ')
           << ": " << msg << std::endl;
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

std::string Logger::getPrefix(LogCategory cat, LogLevel lvl) const
{
  switch (lvl) {
  case(LL_DEBUG):
    return "DEBUG  : ";
  case(LL_ERROR):
    return "ERROR  : ";
  case(LL_INFO):
    return "INFO   : ";
  case(LL_WARNING):
    return "WARNING: ";
  default:
    return "";
  }
}

std::string Logger::getCategory(LogCategory cat) const
{
  switch (cat) {
  case(LC_INIT):
    return "init";
  case(LC_NLS):
    return "nls";
  case(LC_LS):
    return "ls";
  case(LC_SOLVER):
    return "solver";
  case(LC_OUTPUT):
    return "output";
  case(LC_EVENTS):
    return "events";
  case(LC_MODEL):
    return "model";
  case(LC_OTHER):
  default:
    return "other";
  }
}

std::string Logger::getLevel(LogLevel lvl) const
{
  switch(lvl) {
  case(LL_ERROR):
    return "error";
  case(LL_WARNING):
    return "warning";
  case(LL_DEBUG):
    //return "debug"; // avoid red color in OMEdit
  case(LL_INFO):
  default:
    return "info";
  }
}

LoggerXML::LoggerXML(LogSettings settings, bool enabled, std::ostream &stream)
  : Logger(settings, enabled)
  , _stream(stream)
{
}

LoggerXML::~LoggerXML()
{
}

void LoggerXML::writeInternal(std::string msg, LogCategory cat, LogLevel lvl,
                              LogStructure ls)
{
  if (ls != LS_END) {
    _stream << "<message stream=\"" << getCategory(cat) << "\" "
            << "type=\"" << getLevel(lvl) << "\" "
            << "text=\"" << msg << "\"";
    if (ls == LS_BEGIN)
      _stream << " >" << std::endl;
    else
      _stream << " />" << std::endl;
  }
  else {
    _stream << "</message>" << std::endl;
  }
}
