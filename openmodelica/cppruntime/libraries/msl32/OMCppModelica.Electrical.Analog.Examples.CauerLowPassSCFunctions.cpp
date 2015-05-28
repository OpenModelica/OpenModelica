/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCFunctions.h" */


Functions::Functions(double& simTime, double* z, double* zDot, bool& initial, bool& terminate)
    : _simTime(simTime)
    , __z(z)
    , __zDot(zDot)
    , _initial(initial)
    , _terminate(terminate)
{
    _OMC_LIT0 = "'p";
    _OMC_LIT1 = "'p/s";
}

Functions::~Functions()
{
}

void Functions::Assert(bool cond, string msg)
{
  if(!cond)
   throw ModelicaSimulationError(MODEL_EQ_SYSTEM,msg);
}

/*extraFuncs*/
