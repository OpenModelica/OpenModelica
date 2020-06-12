#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */

/*****************************************************************************/
/**

Encapsulation of general solver settings.

\date     October, 1st, 2008
\author


*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class BOOST_EXTENSION_SOLVERSETTINGS_DECL SolverSettings : public ISolverSettings
{
public:
  SolverSettings(IGlobalSettings* globalSettings);
  virtual ~SolverSettings();
  /// Initial step size (default: 1e-2)
  virtual double gethInit();
  virtual void sethInit(double);
  /// Lower limit for step size during integration (default: should be machine precision)
  virtual double getLowerLimit();
  virtual void setLowerLimit(double);
  /// Upper limit for step size during integration (default: _endTime-_startTime)
  virtual double getUpperLimit();
  virtual void setUpperLimit(double);
  /// Tolerance to reach _endTime (default: 1e-6)
  virtual double getEndTimeTol();
  virtual void setEndTimeTol(double);

  //dense Output
  virtual bool getDenseOutput();
  virtual void setDenseOutput(bool);

  virtual double getATol();
  virtual void setATol(double);
  virtual double getRTol();
  virtual void setRTol(double);

  ///  Global simulation settings
  virtual IGlobalSettings* getGlobalSettings();
  virtual void load(string);

private:
  double
    _hInit,             ///< Initial step size (default: 1e-2)
    _hLowerLimit,       ///< Lower limit for step size during integration (default: should be machine precision)
    _hUpperLimit,       ///< Upper limit for step size during integration (default: _endTime-_startTime)
    _endTimeTol,        ///< Tolerance to reach _endTime (default: 1e-6)
    _dRtol,
    _dAtol;
  IGlobalSettings*
    _globalSettings;    ///< Global simulation settings

  bool
    _denseOutput;
};
 /** @} */ // end of coreSolver
