/** @addtogroup solverCvode
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>


#include <Solver/Hybrj/HybrjSettings.h>

HybrjSettings::HybrjSettings()
: _iNewt_max                    (50)
, _dRtol                        (1e-6)
, _dAtol                        (1.0)
, _dDelta                    (0.9)
, _continueOnError(false)
{
};
/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
long int     HybrjSettings::getNewtMax()
{
    return _iNewt_max;
}
void         HybrjSettings::setNewtMax(long int max)
{
    _iNewt_max =max;
}
/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
double         HybrjSettings::getRtol()
{
    return _dRtol;
}
void         HybrjSettings::setRtol(double t)
{
    _dRtol=t;
}
/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
double         HybrjSettings::getAtol()
{
    return _dAtol;
}
void         HybrjSettings::setAtol(double t)
{
    _dAtol =t;
}
/*Dämpfungsfaktor (default: 0.9)*/
double         HybrjSettings::getDelta()
{
    return _dDelta;
}
void         HybrjSettings::setDelta(double t)
{
    _dDelta = t;
}

void HybrjSettings::load(string)
{
}

void HybrjSettings::setContinueOnError(bool value)
{
  _continueOnError = value;
}

bool HybrjSettings::getContinueOnError()
{
  return _continueOnError;
}
/** @} */ // end of solverHybrj
