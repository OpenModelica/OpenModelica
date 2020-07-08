#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */
/*****************************************************************************/
/**

Abstract interface class for numerical time integration methods
in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class ISolver
{
public:
  /// Enumeration to control the time integration
  enum SOLVERCALL
  {
    UNDEF_CALL      = 0x00000000,
    FIRST_CALL      = 0x00000100,    ///< First call to solver
    RECALL          = 0x00000400,    ///< Call to solver after restart (state vector of solver has to be reinitialized
    RECORDCALL      = 0x00004000,    ///< Erster Aufruf zum recorden von y0
  };

  /// Enum to define the current status of the solver
  enum SOLVERSTATUS
  {
    UNDEF_STATUS    = 0x00000,
    CONTINUE        = 0x00001,       ///< Continue integration
    USER_STOP       = 0x00002,       ///< Integration stopped by user
    SOLVERERROR     = 0x00004,       ///< An error occurred. Integration was stopped
    DONE            = 0x00008,       ///< Integration successfully done
  };

  /// Enumeration to denote the event status
  enum ZEROSTATUS
  {
    EQUAL_ZERO,                      ///< Value of zero function smaller than given tolerance (_zeroTol)
    ZERO_CROSSING,                   ///< zero crossing = change in sign of zero function
    NO_ZERO,                         ///< Even though zero crossing occurred, no value of zero function did not become zero in given interval
    UNCHANGED_SIGN                   ///< no zero crossing = continue time integration
  };

  virtual ~ISolver()  {};

  /// Set start time
  virtual void setStartTime(const double& time) = 0;

  /// Set end time
  virtual void setEndTime(const double& time) = 0;

  /// Set the initial step size (needed for reinitialization after external zero search)
  virtual void setInitStepSize(const double& stepSize) = 0;

   /// (Re-) initialize the solver
  virtual void initialize() = 0;
  virtual bool stateSelection() = 0;
  /// Approximation of the numerical solution in a given time interval
  virtual void solve(const SOLVERCALL command = UNDEF_CALL) = 0;

  /// Provides the status of the solver after returning
  virtual SOLVERSTATUS getSolverStatus() = 0;
   ///sets time out in secondsW
  virtual void setTimeOut(unsigned int time_out) = 0;

  virtual void stop() = 0;

  /// Write out statistical information (statistical information of last simulation, e.g. time, number of steps, etc.)
  virtual void writeSimulationInfo() = 0;

  /// Indicates whether a solver error occurred during integration, returns type of error and provides error message
  /*virtual int reportErrorMessage(ostream& messageStream) = 0;*/
};
 /** @} */ // end of coreSolver