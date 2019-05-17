/** @addtogroup fmu2
 *
 *  @{
 */
#pragma once
/*
 * Define default global settings for FMI 2.0.
 *
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include <Core/SimulationSettings/IGlobalSettings.h>

#ifdef ENABLE_SUNDIALS_STATIC
  #define DEFAULT_NLS "kinsol"
#else
  #define DEFAULT_NLS "newton"
#endif

#pragma once

/** @addtogroup coreSimulationSettings
 *
 *  @{
 */

#include <fstream>

class OMSIGlobalSettings : public IGlobalSettings
{
public:
  OMSIGlobalSettings(void);
  ~OMSIGlobalSettings(void);
  ///< Start time of integration (default: 0.0)
  virtual double getStartTime();
  virtual void setStartTime(double);
  ///< End time of integraiton (default: 1.0)
  virtual double getEndTime();
  virtual void setEndTime(double);
  ///< Output step size (default: 20 ms)
  virtual double gethOutput();
  virtual void sethOutput(double);
  ///< Write out results (default: EMIT_ALL)
  virtual EmitResults getEmitResults();
  virtual void setEmitResults(EmitResults);
  ///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false, true]; default: true)
  virtual bool getInfoOutput();
  virtual void setInfoOutput(bool);
  virtual bool useEndlessSim();
  virtual void useEndlessSim(bool);
  ///path for input files, like init xml
  virtual string getInputPath();
  virtual void setInputPath(string);
  ///path for simulation results in textfile
  virtual string getOutputPath();
  virtual void setOutputPath(string);
   virtual string getInitfilePath();
  virtual void setInitfilePath(string);
  virtual OutputPointType getOutputPointType();
  virtual void setOutputPointType(OutputPointType);
  virtual LogSettings getLogSettings();
  virtual void setLogSettings(LogSettings);
  virtual OutputFormat getOutputFormat();
  virtual void setOutputFormat(OutputFormat);
  //solver used for simulation
  virtual string getSelectedSolver();
  virtual void setSelectedSolver(string);
  virtual string getSelectedNonLinSolver();
  virtual void setSelectedNonLinSolver(string);
  virtual string getSelectedLinSolver();
  virtual void setSelectedLinSolver(string);
  virtual void setResultsFileName(string);
  virtual string getResultsFileName();
  //initializes the settings object by an xml file
  void load(std::string xml_file);
  virtual void setRuntimeLibrarypath(string);
  virtual string getRuntimeLibrarypath();
  virtual void setAlarmTime(unsigned int);
  virtual unsigned int getAlarmTime();

  virtual void setNonLinearSolverContinueOnError(bool);
  virtual bool getNonLinearSolverContinueOnError();

  virtual void setSolverThreads(int);
  virtual int getSolverThreads();

private:
  double
      _startTime,   ///< Start time of integration (default: 0.0)
      _endTime,     ///< End time of integraiton (default: 1.0)
      _hOutput;     ///< Output step size (default: 20 ms)
  EmitResults
      _emitResults; ///< Write out results (default: EMIT_ALL)
  bool
      _infoOutput,  ///< Write out statistical simulation infos, e.g. number of steps (at the end of simulation); [false,true]; default: true)
      _endless_sim,
      _nonLinSolverContinueOnError;
  string
      _input_path,
      _output_path,
      _init_file_path,
      _selected_solver,
      _selected_lin_solver,
      _selected_nonlin_solver,
      _resultsfile_name,
      _runtimeLibraryPath;
  OutputPointType _outputPointType;
  LogSettings _log_settings;
  unsigned int _alarm_time;
  int _solverThreads;
  OutputFormat _outputFormat;
};
/** @} */ // end of coreSimulationSettings

/** @} */ // end of fmu2
