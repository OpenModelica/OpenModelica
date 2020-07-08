#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */


/*****************************************************************************/
/**

Abstract interface class for general solver settings.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

class ISolverSettings
{
public:
  virtual ~ISolverSettings()  {};
  /// Initial step size (default: 1e-2)
  virtual double gethInit() = 0;
  virtual void sethInit(double)=0;
  /// Lower limit for step size during integration (default: should be machine precision)
  virtual double getLowerLimit() = 0;
  virtual void setLowerLimit(double)=0;
  /// Upper limit for step size during integration (default: _endTime-_startTime)
  virtual double getUpperLimit() = 0;
  virtual void setUpperLimit(double) = 0;
  /// Tolerance to reach _endTime (default: 1e-6)
  virtual double getEndTimeTol() = 0;
  virtual void setEndTimeTol(double) = 0;
  // DenseOut
  virtual bool getDenseOutput() = 0;
  virtual void setDenseOutput(bool) = 0;

  virtual double getATol() = 0;
  virtual void setATol(double) = 0;
  virtual double getRTol() = 0;
  virtual void setRTol(double) = 0;

  /// Global simulation settings
  virtual IGlobalSettings* getGlobalSettings() = 0;
  virtual void load(string) = 0;
};
 /** @} */ // end of coreSolver