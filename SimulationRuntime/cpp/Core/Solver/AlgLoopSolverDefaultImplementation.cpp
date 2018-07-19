/** @addtogroup coreSolver
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Solver/FactoryExport.h>
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>


AlgLoopSolverDefaultImplementation::AlgLoopSolverDefaultImplementation()
:_dimZeroFunc(-1)
, _dimSys(-1)
,_algloopVars(NULL)
,_conditions0(NULL)
,_conditions1(NULL)
{

}

AlgLoopSolverDefaultImplementation::~AlgLoopSolverDefaultImplementation()
{
 if(_algloopVars)
       delete [] _algloopVars;
     if(_conditions0)
       delete [] _conditions0;
     if(_conditions1)
       delete [] _conditions1;
}
bool* AlgLoopSolverDefaultImplementation::getConditionsWorkArray()
{
	if(_conditions0)
	  return _conditions0;
    else
		ModelicaSimulationError(ALGLOOP_SOLVER, "algloop working arrays are not initialized");

}
bool* AlgLoopSolverDefaultImplementation::getConditions2WorkArray()
{
	if(_conditions1)
	  return _conditions1;
    else
	  ModelicaSimulationError(ALGLOOP_SOLVER, "algloop working arrays are not initialized");
 }


 double* AlgLoopSolverDefaultImplementation::getVariableWorkArray()
 {
	if(_algloopVars)
	  return _algloopVars;
    else
		ModelicaSimulationError(ALGLOOP_SOLVER, "algloop working arrays are not initialized");

 }

void AlgLoopSolverDefaultImplementation::initialize(int dimZeroFunc,int dimSys)
{
  _dimZeroFunc = dimZeroFunc;
  if(_conditions0)
     delete [] _conditions0;
  if(_conditions1)
    delete [] _conditions1;
    _conditions0 = new bool[_dimZeroFunc];
    _conditions1 = new bool[_dimZeroFunc];
    _dimSys=dimSys;
  if(_algloopVars)
      delete [] _algloopVars;
  _algloopVars = new double[_dimSys];
  memset(_algloopVars, 0, _dimSys*sizeof(double));
}
 /** @} */ // end of coreSolver
