/*
 * logger.cpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */
#include <Core/Utils/extension/logger.hpp>

Logger* Logger::instance = 0;

Logger::Logger(bool enabled) : _isEnabled(enabled)
{
}

Logger::~Logger()
{
}

void Logger::writeErrorInternal(std::string errorMsg)
{
  if(_isEnabled)
    std::cerr << "Error: " << errorMsg << std::endl;
}

void Logger::writeWarningInternal(std::string warningMsg)
{
  if(_isEnabled)
    std::cerr << "Warning: " << warningMsg << std::endl;
}

void Logger::writeInfoInternal(std::string infoMsg)
{
  if(_isEnabled)
    std::cout << "Info: " << infoMsg << std::endl;
}

void Logger::setEnabledInternal(bool enabled)
{
  _isEnabled = enabled;
}

bool Logger::isEnabledInternal()
{
  return _isEnabled;
}
