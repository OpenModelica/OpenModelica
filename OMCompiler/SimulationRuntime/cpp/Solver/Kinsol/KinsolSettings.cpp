#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverKinsol
 *
 *  @{
 */

#include <Solver/Kinsol/KinsolSettings.h>

KinsolSettings::KinsolSettings()
: _iNewt_max         (700)
, _dRtol           (1e-12)
, _dAtol           (1.0)
, _dDelta          (0.9)
, _continueOnError(false)
{
};
/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
long int     KinsolSettings::getNewtMax()
{
  return _iNewt_max;
}
void     KinsolSettings::setNewtMax(long int max)
{
  _iNewt_max =max;
}
/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
double     KinsolSettings::getRtol()
{
  return _dRtol;
}
void     KinsolSettings::setRtol(double t)
{
  _dRtol=t;
}
/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
double     KinsolSettings::getAtol()
{
  return _dAtol;
}
void     KinsolSettings::setAtol(double t)
{
  _dAtol =t;
}
/*Dämpfungsfaktor (default: 0.9)*/
double       KinsolSettings::getDelta()
{
  return _dDelta;
}
void       KinsolSettings::setDelta(double t)
{
  _dDelta = t;
}

void KinsolSettings::load(string)
{
}

void KinsolSettings::setContinueOnError(bool value)
{
  _continueOnError = value;
}

bool KinsolSettings::getContinueOnError()
{
  return _continueOnError;
}
/** @} */ // end of solverKinsol
