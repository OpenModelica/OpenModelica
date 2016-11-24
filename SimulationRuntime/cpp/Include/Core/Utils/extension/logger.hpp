/*
 * logger.hpp
 *
 *  Created on: 04.06.2015
 *      Author: marcus and rfranke
 */

#ifndef LOGGER_HPP_
#define LOGGER_HPP_

#ifdef USE_LOGGER
  // check for log settings to avoid construction of unused log strings
  #define LOGGER_IS_SET(cat, lvl) Logger::getInstance()->isSet(cat, lvl)
  #define LOGGER_WRITE(msg, cat, lvl) \
    if (LOGGER_IS_SET(cat, lvl)) Logger::write(msg, cat, lvl)
  #define LOGGER_WRITE_TUPLE(msg, mode) \
    if (LOGGER_IS_SET(mode.first, mode.second)) Logger::write(msg, mode)
  #define LOGGER_WRITE_BEGIN(msg, cat, lvl) \
    if (LOGGER_IS_SET(cat, lvl)) Logger::writeBegin(msg, cat, lvl)
  #define LOGGER_WRITE_END(cat, lvl) Logger::writeEnd(cat, lvl)
  #define LOGGER_WRITE_VECTOR(name, vec, dim, lc, ll) \
    Logger::writeVector(name, vec, dim, lc, ll)
#else
  #define LOGGER_IS_SET(cat, lvl) false
  #define LOGGER_WRITE(msg, cat, lvl)
  #define LOGGER_WRITE_TUPLE(msg, mode)
  #define LOGGER_WRITE_BEGIN(msg, cat, lvl)
  #define LOGGER_WRITE_END(cat, lvl)
  #define LOGGER_WRITE_VECTOR(name, vec, dim, lc, ll)
#endif //USE_LOGGER

class BOOST_EXTENSION_LOGGER_DECL Logger
{
  public:
    virtual ~Logger();

    static Logger* getInstance()
    {
      if (instance == NULL)
        initialize(LogSettings());

      return instance;
    }

    static void initialize(LogSettings settings);

    static void initialize()
    {
      initialize(LogSettings());
    }

    static inline void write(std::string msg, LogCategory cat, LogLevel lvl)
    {
      if (instance && instance->isSet(cat, lvl))
        instance->writeInternal(msg, cat, lvl, LS_NONE);
    }

    static inline void writeBegin(std::string msg, LogCategory cat, LogLevel lvl)
    {
      if (instance && instance->isSet(cat, lvl))
        instance->writeInternal(msg, cat, lvl, LS_BEGIN);
    }

    static inline void writeEnd(LogCategory cat, LogLevel lvl)
    {
      if (instance && instance->isSet(cat, lvl))
        instance->writeInternal("", cat, lvl, LS_END);
    }

    static inline void write(std::string msg, std::pair<LogCategory,LogLevel> mode)
    {
      write(msg, mode.first, mode.second);
    }

    template <typename S, typename T>
    static inline void writeVector(S name, T vec[], size_t dim, LogCategory lc, LogLevel ll)
    {
      if (Logger::getInstance()->isSet(lc, ll)) {
        std::stringstream ss;
        ss << name << " = {";
        for (size_t i = 0; i < dim; i++)
          ss <<  (i > 0? ", ": "") << vec[i];
        ss << "}";
        write(ss.str(), lc, ll);
      }
    }

    static void setEnabled(bool enabled)
    {
      getInstance()->setEnabledInternal(enabled);
    }

    static bool isEnabled()
    {
      return instance != NULL && instance->isEnabledInternal();
    }

    static std::pair<LogCategory,LogLevel> getLogMode(LogCategory cat, LogLevel lvl)
    {
      return std::pair<LogCategory, LogLevel>(cat, lvl);
    }

    void setAll(LogLevel lvl)
    {
      _settings.setAll(lvl);
    }

    void set(LogCategory cat, LogLevel lvl)
    {
      _settings.modes[cat] = lvl;
    }

    bool isSet(LogCategory cat, LogLevel lvl) const
    {
      return _isEnabled && _settings.modes[cat] >= lvl;
    }

    bool isSet(std::pair<LogCategory,LogLevel> mode) const
    {
      return isSet(mode.first, mode.second);
    }

  protected:
    Logger(LogSettings settings, bool enabled);

    Logger(bool enabled);

    enum LogStructure {LS_NONE, LS_BEGIN, LS_END};

    virtual void writeInternal(std::string msg, LogCategory cat, LogLevel lvl,
                               LogStructure ls);

    virtual void setEnabledInternal(bool enabled);
    virtual bool isEnabledInternal();

    std::string getPrefix(LogCategory cat, LogLevel lvl) const;
    std::string getCategory(LogCategory cat) const;
    std::string getLevel(LogLevel lvl) const;

    static Logger* instance;

  private:
    LogSettings _settings;
    bool _isEnabled;
};

class BOOST_EXTENSION_LOGGER_DECL LoggerXML: public Logger
{
  friend class Logger;

  public:
    virtual ~LoggerXML();

  protected:
    LoggerXML(LogSettings settings, bool enabled, std::ostream &stream = std::cout);

    virtual void writeInternal(std::string msg, LogCategory cat, LogLevel lvl,
                               LogStructure ls);
    std::ostream &_stream;
};

#endif /* LOGGER_HPP_ */
