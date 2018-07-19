/** @addtogroup solverNewton
 *
 *  @{
 */

#pragma once

#include <Core/System/ILinearAlgLoop.h>                // Interface to AlgLoo
#include <Core/System/INonLinearAlgLoop.h>                // Interface to AlgLoo
#include <Core/Solver/INonLinearAlgLoopSolver.h>        // Export function from dll
#include <Core/Solver/INonLinSolverSettings.h>
#include <Solver/Newton/NewtonSettings.h>
#include "FactoryExport.h"
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>


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
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 *****************************************************************************/
class Newton : public INonLinearAlgLoopSolver,  public AlgLoopSolverDefaultImplementation
{
 public:
  Newton(INonLinSolverSettings* settings,shared_ptr<INonLinearAlgLoop> algLoop=shared_ptr<INonLinearAlgLoop>());

  virtual ~Newton();

  /// (Re-) initialize the solver
  virtual void initialize();

   /// Solution of a (non-)linear system of equations
   virtual void solve();
   //solve for a single instance call
   virtual void solve(shared_ptr<INonLinearAlgLoop> algLoop,bool first_solve = false);

  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus();
  virtual void stepCompleted(double time);
  virtual void restoreOldValues();
  virtual void restoreNewValues();

  virtual bool* getConditionsWorkArray();
  virtual bool* getConditions2WorkArray();
  virtual double* getVariableWorkArray();


 private:
  /// Encapsulation of determination of residuals to given unknowns
  void calcFunction(const double* y, double* residual);

  /// Encapsulation of determination of Jacobian
  void calcJacobian(double *jac, double *fNominal);

  // Member variables
  //---------------------------------------------------------------
  INonLinSolverSettings
    *_newtonSettings;           ///< Settings for the solver

   shared_ptr<INonLinearAlgLoop> _algLoop;                  ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;           ///< Output      - Denotes the status of iteration



  bool
    _firstCall;                 ///< Temp        - Denotes the first call to the solver, init() is called

  const char*
    *_yNames;                  ///< Names of variables
  double
    *_yNominal,
    *_yMin,
    *_yMax,
    *_y,                        ///< Temp        - Unknowns
    *_fNominal,
    *_f,                        ///< Temp        - Residuals
    *_yHelp,                    ///< Temp        - Auxillary variables
    *_fHelp,                    ///< Temp        - Auxillary variables
    *_yTest,                    ///< Temp        - Auxillary variables
    *_fTest,                    ///< Temp        - Auxillary variables
    *_jac;                      ///< Temp        - Jacobian
  long int *_iHelp;
  LogCategory _lc;              ///< LC_NLS or LC_LS

};/** @} */ // end of solverNewton
