/** @addtogroup solverEuler
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Euler/EulerSettings.h>

EulerSettings::EulerSettings(IGlobalSettings* globalSettings)
: SolverSettings        (globalSettings)
, _method                (EULERFORWARD)
, _zeroSearchMethod        (BISECTION)
, _denseOutput            (true)
, _useSturmSequence        (false)
, _useNewtonIteration    (false)
, _iterTol                (1e-8)
{
}


unsigned int EulerSettings::getEulerMethod()
{
    return _method;
}
void EulerSettings::setEulerMetoh(unsigned int method)
{
    _method= method;
}

unsigned int EulerSettings::getZeroSearchMethod()
{
    return _zeroSearchMethod;
}
void EulerSettings::setZeroSearchMethod(unsigned int method )
{
    _zeroSearchMethod= method;
}

bool EulerSettings::getUseSturmSequence()
{
    return _useSturmSequence;
}
void EulerSettings::setUseSturmSequence(bool use)
{
    _useSturmSequence= use;
}

bool EulerSettings::getUseNewtonIteration()
{
    return _useNewtonIteration;
}
void EulerSettings::setUseNewtonIteration(bool use)
{
    _useNewtonIteration= use;
}

bool EulerSettings::getDenseOutput()
{
    return _denseOutput;
}
void EulerSettings::setDenseOutput(bool dense)
{
    _denseOutput = dense;
}

double EulerSettings::getIterTol()
{
    return _iterTol;
}
void EulerSettings::setIterTol(double tol)
{
    _iterTol = tol;
}

/**
initializes settings object by an xml file
*/
void EulerSettings::load(std::string xml_file)
{



}

/** @} */ // end of solverEuler
