#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */
#include <Core/Solver/SystemStateSelection.h>
#include <Core/Solver/SimulationMonitor.h>
#ifdef RUNTIME_PROFILING
#include <Core/Utils/extension/measure_time.hpp>
#endif

/// typedef to hand over (callback) functions to fortran routines
typedef int (*U_fp)(...);

/*****************************************************************************/
/**

Services, which can be used by numerical integration methods (solver).
Implementation of standart functions (e.g. setStartTime(...), etc.).
Provision of member variables used by all solvers.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

class BOOST_EXTENSION_SOLVER_DECL SolverDefaultImplementation : public SimulationMonitor
{
public:
  void updateEventState();
  SolverDefaultImplementation(IMixedSystem* system, ISolverSettings* settings);
  virtual ~SolverDefaultImplementation();

  /// Set start time for numerical solution
  void setStartTime(const double& t);

  /// Set end time for numerical solution
  void setEndTime(const double& t);

  /// Set the initial step size (needed for reinitialization after external zero search)
  void setInitStepSize(const double& h);

  /// Assemble system and (re-)initialize solver
  void initialize();

  /// Provides the status of the solver after returning
  const ISolver::SOLVERSTATUS getSolverStatus();

  /// Determines current status of a all zero functions (checks for a change in sign in any of all zero functions)
  void setZeroState();

  /// Called by solver after every successful integration step (calls writeOutput)
  void writeToFile(const int& stp, const double& t, const double& h);
  virtual bool stateSelection();

protected:
  // Member variables
  //---------------------------------------------------------------
  IMixedSystem
    *_system;                 ///< System to be solved

  ISolverSettings
    *_settings;               ///< Settings for the solver

  shared_ptr<SystemStateSelection> _state_selection;
  double
    _tInit,                   ///< (initiale) Startzeit (wird nicht vom Solver verändert)
    _tCurrent,                ///< current time (is changed by the solver)
    _tEnd,                    ///< end time
    _tLastSuccess,            ///< time of last successful integration step (before zero crossing)
    _tLastUnsucess,           ///< time of last unsuccessful integration step (after zero crossing)
    _tLargeStep;

  double
    _h;                       ///< step size (changed by the solver)

  bool
    _firstCall,               ///< Denotes the first call to the solver. May be used to call init()
    _firstStep;               ///< Denotes the first step. May be used for (re-)initialization to call giveVars(...)


  int
    _totStps,                 ///< Total number of time integration steps
    _accStps,                 ///< Number of accepted time integration steps
    _rejStps,                 ///< Number of rejected time integration steps
    _zeroStps,                ///< Number of zero search steps during whole time integration interval
    _zeros;                   ///< Number of zeros in whole time integration interval

  int
    _dimSys,                  ///< Number of equations (=dimension of the system)
    _dimZeroFunc;             ///< Number of zero functions

  bool*
    _events;                  ///< Vector (of dimension _dimZeroF) indicating which zero function caused an event

  event_times_type            ///< Map including all time entries and the event ID occurring a time event
    _time_events;

  double
    *_zeroVal,                ///< Vector (of dimension _dimZeroF) containing values of all zero functions
    *_zeroValInit,            ///< Vektor (der Dimension _dimZeroF) mit Nullstellenfunktionswerten am Anfang des Integrationsintervalles
    *_zeroValLastSuccess;     ///< Vector (of dimension _dimZeroF) containing values of all zero functions of last successful integration step (before zero crossing)

  ISolver::ZEROSTATUS
    _zeroStatus;              ///< Denotes whether a change in sign in at least one zero function occured

  ISolver::SOLVERSTATUS
    _solverStatus;            ///< Denotes the current status of the solver

  IWriteOutput::OUTPUT
    _outputCommand;           ///< Controls the output

private:
  /// Definition of signum function
  inline static int sgn (const double &c)
  {
      return (c < 0) ? -1 : ((c == 0) ? 0 : 1);
  }

  #ifdef RUNTIME_PROFILING
  std::vector<MeasureTimeData*> *measureTimeFunctionsArray;
  MeasureTimeValues *writeFunctionStartValues, *writeFunctionEndValues;
  #endif
};
 /** @} */ // end of coreSolver
