#include "stdafx.h"
#define BOOST_EXTENSION_SOLVERSETTINGS_DECL BOOST_EXTENSION_EXPORT_DECL

#include "SolverSettings.h"

SolverSettings::SolverSettings( IGlobalSettings* globalSettings)
  : _hInit    (globalSettings->gethOutput() )
  , _hUpperLimit  (globalSettings->getEndTime() - globalSettings->getStartTime())
  , _hLowerLimit  (10*UROUND)
  , _endTimeTol  (1e-6)
  , _zeroTol    (1e-6)
  , _zeroTimeTol  (1e-10)
  ,_zeroRatio(1.0)
  ,_dRtol(1e-4)
  ,_dAtol(_dRtol)

{  
  _globalSettings = globalSettings ;
}
double SolverSettings::gethInit()
{
  return _hInit;
}
void SolverSettings::sethInit(double h)
{
  _hInit=h;
}
  double SolverSettings::getATol()
  {
    return _dAtol;
  }
   void SolverSettings::setATol(double atol)
   {
   _dAtol=  atol;
   }
    double SolverSettings::getRTol()
  {
    return _dRtol;
  }
   void SolverSettings::setRTol(double rtol )
   {
     _dRtol = rtol;
   }
double SolverSettings::getLowerLimit()
{
  return _hLowerLimit;
}
void SolverSettings::setLowerLimit(double h)
{
  _hLowerLimit=h;
}

double SolverSettings::getUpperLimit()
{
  return _hUpperLimit;
}
void SolverSettings::setUpperLimit(double h)
{
  _hUpperLimit=h;
}

double SolverSettings::getEndTimeTol()
{
  return _endTimeTol;
}
void SolverSettings::setEndTimeTol(double tol)
{
  _endTimeTol=tol;
}

double SolverSettings::getZeroTol()
{
  return _zeroTol;
}
void SolverSettings::setZeroTol(double tol)
{
  _zeroTol=tol;
}

double SolverSettings::getZeroTimeTol()
{
  return _zeroTimeTol;
}
void SolverSettings::setZeroTimeTol(double tol)
{
  _zeroTimeTol=tol;
}

IGlobalSettings* SolverSettings::getGlobalSettings()
{
  return _globalSettings;
}

void SolverSettings::load(string)
{
}

double SolverSettings::getZeroRatio()
{
  return _zeroRatio ;
}

void SolverSettings::setZeroRatio(double ratio)
{
  _zeroRatio=ratio;
}