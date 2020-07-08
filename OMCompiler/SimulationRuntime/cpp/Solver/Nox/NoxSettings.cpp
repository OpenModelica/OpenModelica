#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverNox
 *
 *  @{
 */

 //throw everything away and implement new

#include <Solver/Nox/NoxSettings.h>

NoxSettings::NoxSettings()
: _iNewt_max         (100)
, _dRtol           (1.0e-13)
, _dAtol           (1.0e-13)
, _dDelta          (0.9)
, _continueOnError(false)
{
};
/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
long int     NoxSettings::getNewtMax()
{
  return _iNewt_max;
}
void     NoxSettings::setNewtMax(long int max)
{
  _iNewt_max =max;
}
/* Relative Toleranz für die Newtoniteration (default: 1e-13)*/
double     NoxSettings::getRtol()
{
  return _dRtol;
}
void     NoxSettings::setRtol(double t)
{
  _dRtol=t;
}
/*Absolute Toleranz für die Newtoniteration (default: n/a)*/
double     NoxSettings::getAtol()
{
	throw ModelicaSimulationError(ALGLOOP_SOLVER,"Do not use absolute tolerances in Nox' nonlinear solver settings.");
	return _dAtol;
}
void     NoxSettings::setAtol(double t)
{
	throw ModelicaSimulationError(ALGLOOP_SOLVER,"Do not use absolute tolerances in Nox' nonlinear solver settings.");
	_dAtol =t;
}
/*Dämpfungsfaktor (default: 0.9)*/
double       NoxSettings::getDelta()
{
	throw ModelicaSimulationError(ALGLOOP_SOLVER,"Do not use Delta in Nox' nonlinear solver settings.");
  return _dDelta;
}
void       NoxSettings::setDelta(double t)
{
	throw ModelicaSimulationError(ALGLOOP_SOLVER,"Do not set Delta in Nox' nonlinear solver settings.");
  _dDelta = t;
}

void NoxSettings::load(string)
{
}

void NoxSettings::setContinueOnError(bool value)
{
  _continueOnError = value;
}

bool NoxSettings::getContinueOnError()
{
  return _continueOnError;
}
/** @} */ // end of solverNox
