/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Newton/NewtonSettings.h>

NewtonSettings::NewtonSettings()
  : _iNewt_max                 (50)
  , _dRtol                     (1e-8)
  , _dAtol                     (1e-8)
  , _dDelta                    (1)
  , _continueOnError           (false)
{
}

NewtonSettings::~NewtonSettings()
{
}

/*max. Anzahl an Newtonititerationen pro Schritt (default: 50)*/
long int NewtonSettings::getNewtMax()
{
  return _iNewt_max;
}

void NewtonSettings::setNewtMax(long int max)
{
  _iNewt_max = max;
}

/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
double NewtonSettings::getRtol()
{
  return _dRtol;
}

void NewtonSettings::setRtol(double t)
{
  _dRtol=t;
}

/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
double NewtonSettings::getAtol()
{
  return _dAtol;
}

void NewtonSettings::setAtol(double t)
{
  _dAtol =t;
}

/*Dämpfungsfaktor (default: 0.9)*/
double NewtonSettings::getDelta()
{
  return _dDelta;
}

void NewtonSettings::setDelta(double t)
{
  _dDelta = t;
}

void NewtonSettings::load(string)
{
}

void NewtonSettings::setContinueOnError(bool value)
{
  _continueOnError = value;
}

bool NewtonSettings::getContinueOnError()
{
  return _continueOnError;
}

/** @} */ // end of solverNewton
