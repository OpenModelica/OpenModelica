/** @addtogroup solverBroyden
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>


#include <Solver/Broyden/BroydenSettings.h>

BroydenSettings::BroydenSettings()
: _iNewt_max                    (50)
, _dRtol                        (1e-6)
, _dAtol                        (1e-6)
, _dDelta                    (1)
, _continueOnError(false)
{
};

BroydenSettings::~BroydenSettings()
{

}

/*max. Anzahl an Broydenititerationen pro Schritt (default: 25)*/
long int     BroydenSettings::getNewtMax()
{
    return _iNewt_max;
}
void         BroydenSettings::setNewtMax(long int max)
{
    _iNewt_max =max;
}
/* Relative Toleranz für die Broydeniteration (default: 1e-6)*/
double         BroydenSettings::getRtol()
{
    return _dRtol;
}
void         BroydenSettings::setRtol(double t)
{
    _dRtol=t;
}
/*Absolute Toleranz für die Broydeniteration (default: 1e-6)*/
double         BroydenSettings::getAtol()
{
    return _dAtol;
}
void         BroydenSettings::setAtol(double t)
{
    _dAtol =t;
}
/*Dämpfungsfaktor (default: 0.9)*/
double         BroydenSettings::getDelta()
{
    return _dDelta;
}
void         BroydenSettings::setDelta(double t)
{
    _dDelta = t;
}

void BroydenSettings::load(string)
{
}

void BroydenSettings::setContinueOnError(bool value)
{
  _continueOnError = value;
}

bool BroydenSettings::getContinueOnError()
{
  return _continueOnError;
}
/** @} */ // end of solverBroyden
