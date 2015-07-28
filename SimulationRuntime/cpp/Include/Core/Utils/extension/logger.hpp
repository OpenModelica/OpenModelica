/*
 * logger.hpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */

#ifndef LOGGER_HPP_
#define LOGGER_HPP_

#include <Core/Modelica.h>

class BOOST_EXTENSION_LOGGER_DECL Logger
{
  public:
    virtual ~Logger();

    static Logger* getInstance()
    {
      if(instance == NULL)
        initialize(LogSettings());

      return instance;
    }

    static void initialize(LogSettings settings)
    {
      if(instance != NULL)
        delete instance;

      instance = new Logger(settings, true);
    }

    static void initialize()
    {
      initialize(LogSettings());
    }

    static void write(std::string msg, LogCategory cat, LogLevel lvl)
    {
      Logger* instance = getInstance();
      if(instance && instance->isEnabled())
        instance->writeInternal(msg, cat, lvl);
    }

    static void write(std::string msg, std::pair<LogCategory,LogLevel> mode)
    {
      write(msg, mode.first, mode.second);
    }

    static void setEnabled(bool enabled)
    {
      getInstance()->setEnabledInternal(enabled);
    }

    static bool isEnabled()
    {
      return getInstance()->isEnabledInternal();
    }

    static std::pair<LogCategory,LogLevel> getLogMode(LogCategory cat, LogLevel lvl)
    {
    	return std::pair<LogCategory, LogLevel>(cat, lvl);
    }

    bool isOutput(LogCategory cat, LogLevel lvl) const;

    bool isOutput(std::pair<LogCategory,LogLevel> mode) const;

  protected:
    Logger(LogSettings settings, bool enabled);

    Logger(bool enabled);

    virtual void writeInternal(std::string Msg, LogCategory cat, LogLevel lvl);
    virtual void setEnabledInternal(bool enabled);
    virtual bool isEnabledInternal();

    std::string getPrefix(LogCategory cat, LogLevel lvl) const;


    static Logger* instance;

  private:
    LogSettings _settings;
    bool _isEnabled;
};

#endif /* LOGGER_HPP_ */
