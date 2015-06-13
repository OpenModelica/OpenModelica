/** @addtogroup coreSolver
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Solver/FactoryExport.h>
#include <Core/Solver/SolverSettings.h>
#include <Core/SimulationSettings/IGlobalSettings.h>
//#include "../Interfaces/API.h"
#include <Core/Math/Constants.h>

SolverSettings::SolverSettings(IGlobalSettings* globalSettings)
  : _hInit    (1e-3)
  , _hUpperLimit  (1e-3)
  , _hLowerLimit  (10*UROUND)
  , _endTimeTol  (1e-7)
  , _dRtol    (1e-6)
  , _dAtol    (1e-6)
  , _denseOutput  (false)
{
  _globalSettings = globalSettings ;
}

SolverSettings::~SolverSettings()
{
}

double SolverSettings::gethInit()
{
  return _hInit;
}

void SolverSettings::sethInit(double h)
{
  _hInit = h;
}

double SolverSettings::getATol()
{
  return _dAtol;
}

void SolverSettings::setATol(double atol)
{
  _dAtol = atol;
}

double SolverSettings::getRTol()
{
  return _dRtol;
}

void SolverSettings::setRTol(double rtol)
{
  _dRtol = rtol;
}

double SolverSettings::getLowerLimit()
{
  return _hLowerLimit;
}

void SolverSettings::setLowerLimit(double h)
{
  _hLowerLimit = h;
}

double SolverSettings::getUpperLimit()
{
  return _hUpperLimit;
}

void SolverSettings::setUpperLimit(double h)
{
  _hUpperLimit = h;
}

double SolverSettings::getEndTimeTol()
{
  return _endTimeTol;
}

void SolverSettings::setEndTimeTol(double tol)
{
  _endTimeTol = tol;
}

bool SolverSettings::getDenseOutput()
{
  return _denseOutput;
}

void SolverSettings::setDenseOutput(bool dense)
{
  _denseOutput = dense;
}

IGlobalSettings* SolverSettings::getGlobalSettings()
{
  return _globalSettings;
}

void SolverSettings::load(string)
{
}
 /** @} */ // end of coreSolver


