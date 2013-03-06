#pragma once
#include <SimulationSettings/IGlobalSettings.h>
//#include "Math/Implementation/Constants.h"
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

   virtual double getATol() = 0;
  virtual void setATol(double) = 0;
   virtual double getRTol() = 0;
  virtual void setRTol(double) = 0;
  /// Tolerance to find a zero search (abs(f(t))<_zeroTol) (default: 1e-5)
  virtual double getZeroTol() = 0;
  virtual void setZeroTol(double) = 0;
  /// Tolerance to find the time of a zero ((t-t_last)<_zeroTimeTol) (default: 1e-12)
  virtual double getZeroTimeTol() = 0;
  virtual void setZeroTimeTol(double) = 0;
  virtual double getZeroRatio()= 0;
    virtual void setZeroRatio(double) = 0;
    ///  Global simulation settings
    virtual IGlobalSettings* getGlobalSettings()=0;
    virtual void load(string)=0;
};
