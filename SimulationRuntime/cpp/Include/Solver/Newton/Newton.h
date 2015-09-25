/** @addtogroup solverNewton
 *
 *  @{
 */

#pragma once

#include "FactoryExport.h"

#include <Core/System/IAlgLoop.h>                // Interface to AlgLoo
#include <Core/Solver/IAlgLoopSolver.h>        // Export function from dll
#include <Core/Solver/INonLinSolverSettings.h>
#include <Solver/Newton/NewtonSettings.h>

#include <Core/Utils/extension/logger.hpp>
#if defined(__vxworks)
//#include <klu.h>
#else
//#include <Solver/KLU/klu.h>
#endif

/*****************************************************************************/
/**

Damped Newton-Raphson Method

The purpose of Newton is to find a zero of a system F of n nonlinear functions in n
variables y of the form

F(t,y_1,...,y_n) = 0,                (1)

or

f_1(t,y_1,...,y_n) = 0
...                   ...
f_n(t,y_1,...,y_n) = 0

by the use of an iterative Newton method. The solution of the linear system is done
by Lapack/DGESV, which computes the solution to a real system of linear equations

A * y = B,                            (2)

where A is an n-by-n matrix and y and B are n-by-n(right hand side) matrices.

\date     2008, September, 16th
\author

*/
/*****************************************************************************
OSMS(c) 2008
*****************************************************************************/
class Newton : public IAlgLoopSolver
{
public:

    Newton(IAlgLoop* algLoop,INonLinSolverSettings* settings);

    virtual ~Newton();

    /// (Re-) initialize the solver
    virtual void initialize();

    /// Solution of a (non-)linear system of equations
    virtual void solve();

    /// Returns the status of iteration
    virtual ITERATIONSTATUS getIterationStatus();
    virtual void stepCompleted(double time);
    virtual void restoreOldValues();
    virtual void restoreNewValues();
private:
    /// Encapsulation of determination of residuals to given unknowns
    void calcFunction(const double* y, double* residual);

    /// Encapsulation of determination of Jacobian
    void calcJacobian();

    // Member variables
    //---------------------------------------------------------------
    INonLinSolverSettings
        *_newtonSettings;            ///< Settings for the solver

    IAlgLoop
        *_algLoop;                    ///< Algebraic loop to be solved

    ITERATIONSTATUS
        _iterationStatus;            ///< Output        - Denotes the status of iteration

    long int
        _dimSys,                    ///< Temp        - Number of unknowns (=dimension of system of equations)
		_lwork,
		_iONE;

    bool
        _firstCall;                    ///< Temp        - Denotes the first call to the solver, init() is called

    double
        *_y,                        ///< Temp        - Unknowns
		*_yHelp,
        *_fnew,                        ///< Temp        - Residuals
		*_fold,                        ///< Temp        - Residuals
		*_fHelp,
        *_delta_s,                    ///< Temp        - Auxillary variables
		*_delta_b,                    ///< Temp        - Auxillary variables
        *_jac,                        ///< Temp        - Jacobian
        *_jacHelpMat1,
        *_jacHelpMat2,
		*_jacHelpVec1,
		*_jacHelpVec2,
		*_work;

	int
		_broydenMethod;

	double _fNormTol,
		_dONE,
		_dZERO,
		_dMINUSONE;


  long int *_iHelp;

  char
	  _N,
	  _T;

  bool _sparse;


  int _dim;
  //klu_symbolic* _kluSymbolic ;
  //klu_numeric* _kluNumeric ;
  //klu_common* _kluCommon ;
  int* _Ai;
  int* _Ap;
  double* _Ax;
  int _nonzeros;

  long int* _ihelpArray;
  double * 	_zeroVec;
  double *	 _f ;




  double* _identity;
};
/** @} */ // end of solverNewton
