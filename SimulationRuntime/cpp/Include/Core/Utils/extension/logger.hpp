/*
 * logger.hpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus
 */

#ifndef LOGGER_HPP_
#define LOGGER_HPP_

#include <Core/Modelica.h>

class BOOST_EXTENSION_EXPORT_DECL Logger
{
  public:
    virtual ~Logger();

    static Logger* getInstance()
    {
      if(instance == NULL)
        initialize();

      return instance;
    }

    static void initialize()
    {
      if(instance != NULL)
        delete instance;

      instance = new Logger(true);
    }

    static void writeError(std::string errorMsg)
    {
      getInstance()->writeErrorInternal(errorMsg);
    }

    static void writeWarning(std::string warningMsg)
    {
      getInstance()->writeWarningInternal(warningMsg);
    }

    static void writeInfo(std::string infoMsg)
    {
      getInstance()->writeInfoInternal(infoMsg);
    }

    static void setEnabled(bool enabled)
    {
      getInstance()->setEnabledInternal(enabled);
    }

    static bool isEnabled()
    {
      getInstance()->isEnabledInternal();
    }

  protected:
    Logger(bool enabled);

    virtual void writeErrorInternal(std::string errorMsg);
    virtual void writeWarningInternal(std::string warningMsg);
    virtual void writeInfoInternal(std::string infoMsg);
    virtual void setEnabledInternal(bool enabled);
    virtual bool isEnabledInternal();

    static Logger* instance;

  private:
    bool _isEnabled;
};



#endif /* LOGGER_HPP_ */
