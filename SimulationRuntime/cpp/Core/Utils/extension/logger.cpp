/*
 * logger.cpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */
#include <Core/Utils/extension/logger.hpp>

Logger* Logger::instance = 0;

Logger::Logger()
{
}

Logger::~Logger()
{
}

void Logger::writeErrorInternal(std::string errorMsg)
{
  std::cerr << "Error: " << errorMsg << std::endl;
}

void Logger::writeWarningInternal(std::string warningMsg)
{
  std::cerr << "Warning: " << warningMsg << std::endl;
}

void Logger::writeInfoInternal(std::string infoMsg)
{
  std::cout << "Info: " << infoMsg << std::endl;
}
