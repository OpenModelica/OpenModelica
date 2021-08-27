#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */


/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

class BOOST_EXTENSION_SOLVER_DECL AlgLoopSolverDefaultImplementation
{
  public:
	AlgLoopSolverDefaultImplementation();
	~AlgLoopSolverDefaultImplementation();
 /// (Re-) initialize the solver
  virtual void initialize(int dimZeroFunc,int dimSys);
 virtual bool* getConditionsWorkArray();
  virtual bool* getConditions2WorkArray();
  virtual double* getVariableWorkArray();
protected:
  long int _dimZeroFunc;
  long int    _dimSys;              ///< Number of unknowns (=dimension of system of equations)
  long int _max_dimSys;
  long int _max_dimZeroFunc;
  bool _single_instance;
private:
 double* _algloopVars;
 bool* _conditions0;
 bool* _conditions1;


};
 /** @} */ // end of coreSolver
