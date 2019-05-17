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
  #define LOGGER_IS_SET(cat, lvl) Logger::isSetGlobal(cat, lvl)
  #define LOGGER_WRITE(msg, cat, lvl) \
    if (LOGGER_IS_SET(cat, lvl)) Logger::write(msg, cat, lvl)
  #define LOGGER_WRITE_TUPLE(msg, mode) \
    if (LOGGER_IS_SET(mode.first, mode.second)) Logger::write(msg, mode)
  #define LOGGER_WRITE_BEGIN(msg, cat, lvl) \
    if (LOGGER_IS_SET(cat, lvl)) Logger::writeBegin(msg, cat, lvl)
  #define LOGGER_WRITE_END(cat, lvl) Logger::writeEnd(cat, lvl)
  #define LOGGER_WRITE_VECTOR(name, vec, dim, lc, ll) \
    Logger::writeVector(name, vec, dim, lc, ll)
  #define LOGGER_STATUS_STARTING(startTime, endTime) \
    Logger::statusStarting(startTime, endTime)
  #define LOGGER_STATUS(phase, currentTime, currentStepSize) \
    Logger::status(phase, currentTime, currentStepSize)
#else
  #define LOGGER_IS_SET(cat, lvl) false
  #define LOGGER_WRITE(msg, cat, lvl)
  #define LOGGER_WRITE_TUPLE(msg, mode)
  #define LOGGER_WRITE_BEGIN(msg, cat, lvl)
  #define LOGGER_WRITE_END(cat, lvl)
  #define LOGGER_WRITE_VECTOR(name, vec, dim, lc, ll)
  #define LOGGER_STATUS_STARTING(startTime, endTime)
  #define LOGGER_STATUS(phase, currentTime, currentStepSize)
#endif //USE_LOGGER

class BOOST_EXTENSION_LOGGER_DECL Logger
{
  public:
    virtual ~Logger();

    static Logger* getInstance()
    {
      if (_instance == NULL)
        initialize(LogSettings());

      return _instance;
    }

    static void initialize(LogSettings settings);

    static void initialize()
    {
      initialize(LogSettings());
    }

    static void finalize();

    static inline void write(std::string msg, LogCategory cat, LogLevel lvl)
    {
      if (_instance && _instance->isSet(cat, lvl))
        _instance->writeInternal(msg, cat, lvl, LS_NONE);
    }

    static inline void writeBegin(std::string msg, LogCategory cat, LogLevel lvl)
    {
      if (_instance && _instance->isSet(cat, lvl))
        _instance->writeInternal(msg, cat, lvl, LS_BEGIN);
    }

    static inline void writeEnd(LogCategory cat, LogLevel lvl)
    {
      if (_instance && _instance->isSet(cat, lvl))
        _instance->writeInternal("", cat, lvl, LS_END);
    }

    static inline void write(std::string msg, std::pair<LogCategory,LogLevel> mode)
    {
      write(msg, mode.first, mode.second);
    }

    template <typename S, typename T>
    static inline void writeVector(S name, T vec[], size_t dim, LogCategory lc, LogLevel ll)
    {
      if (isSetGlobal(lc, ll)) {
        std::stringstream ss;
        ss << name << " = {";
        for (size_t i = 0; i < dim; i++)
          ss <<  (i > 0? ", ": "") << vec[i];
        ss << "}";
        write(ss.str(), lc, ll);
      }
    }

    static inline void statusStarting(double startTime, double endTime)
    {
      if (_instance) {
        _instance->_startTime = startTime;
        _instance->_endTime = endTime;
        _instance->statusInternal("Starting", startTime, 0.0);
      }
    }

    static inline void status(const char *phase, double currentTime, double currentStepSize)
    {
      if (_instance)
        _instance->statusInternal(phase, currentTime, currentStepSize);
    }

    static void setEnabled(bool enabled)
    {
      getInstance()->setEnabledInternal(enabled);
    }

    static bool isEnabled()
    {
      return _instance != NULL && _instance->isEnabledInternal();
    }

    static std::pair<LogCategory,LogLevel> getLogMode(LogCategory cat, LogLevel lvl)
    {
      return std::pair<LogCategory, LogLevel>(cat, lvl);
    }

    void setAll(LogLevel lvl)
    {
      _logSettings.setAll(lvl);
    }

    void set(LogCategory cat, LogLevel lvl)
    {
      _logSettings.modes[cat] = lvl;
    }

    bool isSet(LogCategory cat, LogLevel lvl) const
    {
      return _isEnabled && _logSettings.modes[cat] >= lvl;
    }

    bool isSet(std::pair<LogCategory,LogLevel> mode) const
    {
      return isSet(mode.first, mode.second);
    }

    inline static bool isSetGlobal(LogCategory cat, LogLevel lvl)
    {
      return _instance != NULL && _instance->isSet(cat, lvl);
    }

  protected:
    Logger(LogSettings settings, bool enabled);

    enum LogStructure {LS_NONE, LS_BEGIN, LS_END};

    virtual void writeInternal(std::string msg, LogCategory cat, LogLevel lvl,
                               LogStructure ls);

    virtual void statusInternal(const char *phase, double currentTime,
                                double currentStepSize);

    virtual void setEnabledInternal(bool enabled);
    virtual bool isEnabledInternal();

    std::string getPrefix(LogCategory cat, LogLevel lvl) const;
    std::string getCategory(LogCategory cat) const;
    std::string getLevel(LogLevel lvl) const;

    static Logger* _instance;
    double _startTime;
    double _endTime;
    LogSettings _logSettings;
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
