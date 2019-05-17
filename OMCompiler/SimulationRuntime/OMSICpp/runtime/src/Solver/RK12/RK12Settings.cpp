/** @addtogroup solverEuler
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/RK12/RK12Settings.h>

RK12Settings::RK12Settings(IGlobalSettings* globalSettings)
: SolverSettings        (globalSettings)
, _method                (MULTIRATE)
, _zeroSearchMethod        (BISECTION)
, _denseOutput            (true)
, _useSturmSequence        (false)
, _useNewtonIteration    (false)
, _iterTol                (1e-8)
{
}


unsigned int RK12Settings::getRK12Method()
{
    return _method;
}
void RK12Settings::setRK12Method(unsigned int method)
{
    _method= method;
}

unsigned int RK12Settings::getZeroSearchMethod()
{
    return _zeroSearchMethod;
}
void RK12Settings::setZeroSearchMethod(unsigned int method )
{
    _zeroSearchMethod= method;
}

bool RK12Settings::getUseSturmSequence()
{
    return _useSturmSequence;
}
void RK12Settings::setUseSturmSequence(bool use)
{
    _useSturmSequence= use;
}

bool RK12Settings::getUseNewtonIteration()
{
    return _useNewtonIteration;
}
void RK12Settings::setUseNewtonIteration(bool use)
{
    _useNewtonIteration= use;
}

bool RK12Settings::getDenseOutput()
{
    return _denseOutput;
}
void RK12Settings::setDenseOutput(bool dense)
{
    _denseOutput = dense;
}

double RK12Settings::getIterTol()
{
    return _iterTol;
}
void RK12Settings::setIterTol(double tol)
{
    _iterTol = tol;
}

/**
initializes settings object by an xml file
*/
void RK12Settings::load(std::string xml_file)
{



}

/** @} */ // end of solverEuler
