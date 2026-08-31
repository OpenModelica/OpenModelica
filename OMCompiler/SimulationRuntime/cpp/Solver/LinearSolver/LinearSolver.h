/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once
/** @addtogroup solverLinearSolver
 *
 *  @{
 */
#include "FactoryExport.h"
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>

#if defined(klu)
  #include <klu.h>
#endif

class LinearSolver : public ILinearAlgLoopSolver,  public AlgLoopSolverDefaultImplementation
{
public:
  LinearSolver(ILinSolverSettings* settings,shared_ptr<ILinearAlgLoop> algLoop=shared_ptr<ILinearAlgLoop>());
  virtual ~LinearSolver();

  /// (Re-) initialize the solver
  virtual void initialize();

  /// Solution of a (non-)linear system of equations
  virtual void solve();
  //solve for a single instance call
  virtual void solve(shared_ptr<ILinearAlgLoop> algLoop,bool first_solve = false);

  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus();
  virtual void stepCompleted(double time);
  virtual void restoreOldValues();
  virtual void restoreNewValues();


  virtual bool* getConditionsWorkArray();
  virtual bool* getConditions2WorkArray();
  virtual double* getVariableWorkArray();


private:
  // Member variables
  //---------------------------------------------------------------

  shared_ptr<ILinearAlgLoop>
    _algLoop;            ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration



  bool
    _firstCall,           ///< Temp   - Denotes the first call to the solver, init() is called
    _hasDgesvFactors,     ///< =true if dgesv was called previously
    _hasDgetc2Factors;    ///< =true if dgetc2 was called previously

  long int *_ihelpArray,  //pivot indices for lapackroutine
    *_jhelpArray;       //pivot indices for lapackroutine

  const char*
    *_yNames;           ///< Names of variables
  double
    *_yNominal,         ///< Nominal values of variables
    *_y,                ///< Temp   - Unknowns
    *_y0,               ///< Temp   - Auxillary variables
    *_y_old,            //stores old solution
    *_y_new,            //stores new solution
    *_b,                ///< right hand side
    *_A,                ///coefficients of linear system
    *_zeroVec,          ///zero vector
    *_fNominal,         // klu scales the matrix entries already
    *_scale;            //scaling parameter to prevent overflow in singular systems
  bool _sparse;
  bool _generateoutput;   //prints nothing, if set to false. Prints Matrix, right hand side, and solution of the linear system, if set to true.

#if defined(klu)
  klu_symbolic* _kluSymbolic;
  klu_numeric* _kluNumeric;
  klu_common* _kluCommon;
  int* _Ai;
  int* _Ap;
  double* _Ax;
  int _nonzeros;
#endif

};
/** @} */ // end of solverLinearSolver
