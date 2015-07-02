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

// adrpo: the MSVC compiler has issues with some of the enumerations (OUT, DEBUG, ERROR)
enum OutputFormat {OM_CSV, OM_MAT, OM_BUFFER, OM_EMPTY};

enum LogCategory {OM_INIT = 0, OM_NLS = 1, OM_LS = 2, OM_SOLV = 3, OM_OUT = 4, OM_EVT = 5, OM_OTHER = 6, OM_MOD = 7};
enum LogLevel {OM_ERROR = 0, OM_WARNING = 1, OM_INFO = 2, OM_DEBUG = 3};

enum OutputPointType {OM_ALL, OM_STEP, OM_EMPTY2};

struct LogSettings
{
	std::vector<LogLevel> modes;

	LogSettings()
	{
		modes = std::vector<LogLevel>(8,OM_ERROR);
	}

	void setAll(LogLevel l)
	{
		for(unsigned i = 0; i < modes.size() ; ++i)
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
  ///< Write out results ([false,true]; default: true)
  virtual bool getResultsOutput() = 0;
  virtual void setResultsOutput(bool) = 0;
  virtual OutputFormat getOutputFormat() = 0;
  virtual void setOutputFormat(OutputFormat) = 0;
  virtual OutputPointType getOutputPointType() = 0;
  virtual void setOutputPointType(OutputPointType) = 0;
  virtual LogSettings getLogSettings() = 0;
  virtual void setLogSettings(LogSettings) = 0;
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
/** @} */ // end of coreSimulationSettings
