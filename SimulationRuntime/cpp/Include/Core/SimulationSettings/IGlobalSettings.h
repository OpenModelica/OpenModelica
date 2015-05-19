#pragma once

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
enum OutputFormat {CSV, MAT, BUFFER, EMPTY};
enum LogType {OFF, STATS, NLS, ODE};
enum OutputPointType {ALL, STEP, EMPTY2};
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
  ///< Write out results ([false,true]; default: true)
  virtual bool getResultsOutput() = 0;
  virtual void setResultsOutput(bool) = 0;
  virtual OutputFormat getOutputFormat() = 0;
  virtual void setOutputFormat(OutputFormat) = 0;
  virtual OutputPointType getOutputPointType() = 0;
  virtual void setOutputPointType(OutputPointType) = 0;
  virtual LogType getLogType() = 0;
  virtual void setLogType(LogType) = 0;
  virtual void setAlarmTime(unsigned int) = 0;
  virtual unsigned int getAlarmTime() = 0;

  virtual bool useEndlessSim() = 0;
  virtual void useEndlessSim(bool) = 0;
  ///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
  virtual bool getInfoOutput() = 0;
  virtual void setInfoOutput(bool) = 0;
  virtual string getOutputPath() = 0;
  virtual void setOutputPath(string)= 0;
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
};
