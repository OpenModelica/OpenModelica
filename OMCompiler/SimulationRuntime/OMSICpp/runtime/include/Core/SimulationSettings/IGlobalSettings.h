#pragma once
/** @addtogroup coreSimulationSettings
 *
 *  @{
 */

/*****************************************************************************/
/**

Encapsulation of global simulation settings.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <string.h>
using std::string;
#endif
*/

#include <vector>

enum LogCategory {LC_INIT = 0, LC_NLS = 1, LC_LS = 2, LC_SOLVER = 3, LC_OUTPUT = 4, LC_EVENTS = 5, LC_OTHER = 6, LC_MODEL = 7};
enum LogLevel {LL_ERROR = 0, LL_WARNING = 1, LL_INFO = 2, LL_DEBUG = 3};
enum LogFormat {LF_TXT = 0, LF_FMI = 1, LF_FMI2 = 2, LF_XML = 3, LF_XMLTCP = 4};
enum LogOMEdit {LOG_EVENTS = 0, LOG_INIT, LOG_LS, LOG_NLS, LOG_SOLVER, LOG_STATS};
enum OutputPointType {OPT_ALL, OPT_STEP, OPT_NONE};
enum OutputFormat {CSV, MAT, BUFFER, EMPTY};
enum EmitResults {EMIT_ALL, EMIT_PUBLIC, EMIT_NONE};

struct LogSettings
{
  std::vector<LogLevel> modes;
  LogFormat format;

  LogSettings(LogFormat fmt = LF_TXT)
  {
    modes = std::vector<LogLevel>(8, LL_ERROR);
    format = fmt;
  }

  void setAll(LogLevel l)
  {
    for (unsigned i = 0; i < modes.size() ; ++i)
      modes[i] = l;
  }
};

class IGlobalSettings
{
public:
  virtual ~IGlobalSettings() {}
  ///< Start time of integration (default: 0.0)
  virtual double getStartTime() = 0;
  virtual void setStartTime(double) = 0;
  ///< End time of integration (default: 1.0)
  virtual double getEndTime() = 0;
  virtual void setEndTime(double) = 0;
  ///< Output step size (default: 20 ms)
  virtual double gethOutput() = 0;
  virtual void sethOutput(double) = 0;
  ///< Write out results (default: EMIT_ALL)
  virtual EmitResults getEmitResults() = 0;
  virtual void setEmitResults(EmitResults) = 0;
  virtual OutputPointType getOutputPointType() = 0;
  virtual void setOutputPointType(OutputPointType) = 0;
  virtual LogSettings getLogSettings() = 0;
  virtual void setLogSettings(LogSettings) = 0;
  virtual void setAlarmTime(unsigned int) = 0;
  virtual unsigned int getAlarmTime() = 0;

  virtual OutputFormat getOutputFormat() = 0;
  virtual void setOutputFormat(OutputFormat) = 0;
  virtual bool useEndlessSim() = 0;
  virtual void useEndlessSim(bool) = 0;
  ///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
  virtual bool getInfoOutput() = 0;
  virtual void setInfoOutput(bool) = 0;
  virtual string getOutputPath() = 0;
  virtual void setOutputPath(string)= 0;
  virtual string getInitfilePath() = 0;
  virtual void setInitfilePath(string)= 0;

  virtual string getSelectedSolver() = 0;
  virtual void setSelectedSolver(string) = 0;
  virtual string getSelectedLinSolver() = 0;
  virtual void setSelectedLinSolver(string) = 0;
  virtual string getSelectedNonLinSolver() = 0;
  virtual void setSelectedNonLinSolver(string) = 0;
  virtual void load(std::string xml_file) = 0;
  virtual void setResultsFileName(string) = 0;
  virtual string getResultsFileName() = 0;
  virtual void setRuntimeLibrarypath(string) = 0;
  virtual string getRuntimeLibrarypath() = 0;
  ///< Directory for input files, like init.xml
  virtual string getInputPath() = 0;
  virtual void setInputPath(string) = 0;

  virtual void setNonLinearSolverContinueOnError(bool) = 0;
  virtual bool getNonLinearSolverContinueOnError() = 0;

  virtual void setSolverThreads(int) = 0;
  virtual int getSolverThreads() = 0;
};
/** @} */ // end of coreSimulationSettings
