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
 * logger.cpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus and rfranke
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Utils/extension/FactoryExport.h>
#include <Core/Utils/extension/logger.hpp>

#include <boost/property_tree/xml_parser.hpp>
using boost::property_tree::xml_parser::encode_char_entities;

Logger* Logger::_instance = NULL;

Logger::Logger(LogSettings settings, bool enabled)
  : _logSettings(settings)
  , _isEnabled(enabled)
{
  if (_instance != NULL)
    delete _instance;
  _instance = NULL;
  _startTime = _endTime = 0.0;
}

Logger::~Logger()
{
}

void Logger::initialize(LogSettings settings)
{
  switch (settings.format) {
  case LF_TXT:
    _instance = new Logger(settings, true);
    break;
  default:
    _instance = new LoggerXML(settings, true);
  }
}

void Logger::finalize()
{
  if (_instance != NULL)
    delete _instance;
  _instance = NULL;
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

void Logger::statusInternal(const char *, double, double)
{
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
    return "debug";
  case(LL_INFO):
    return "info";
  default:
    return "unknown";
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
            << "text=\"" << encode_char_entities(msg) << "\"";
    if (ls == LS_BEGIN)
      _stream << " >" << std::endl;
    else
      _stream << " />" << std::endl;
  }
  else {
    _stream << "</message>" << std::endl;
  }
}
