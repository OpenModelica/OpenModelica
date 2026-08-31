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
/** @addtogroup solverDgesvSolver
 *
 *  @{
 */

#include "FactoryExport.h"
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>


class DgesvSolver : public ILinearAlgLoopSolver,  public AlgLoopSolverDefaultImplementation
{
 public:
  DgesvSolver(ILinSolverSettings* settings,shared_ptr<ILinearAlgLoop> algLoop=shared_ptr<ILinearAlgLoop>());
  virtual ~DgesvSolver();

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

  shared_ptr<ILinearAlgLoop> _algLoop;            ///< Algebraic loop to be solved

  ITERATIONSTATUS
    _iterationStatus;     ///< Output   - Denotes the status of iteration

  long int

    *_iHelp,              ///< Pivot indices for LAPACK routines
    *_jHelp;              ///< Pivot indices for LAPACK routines

  bool
    _firstCall,           ///< Temp   - Denotes the first call to the solver, init() is called
    _hasDgesvFactors,    ///< =true if previous dgesv was called
    _hasDgetc2Factors;   ///< =true if previous dgetc2 was called

  const char*
    *_yNames;             ///< Names of variables
  double
    *_yNominal,           ///< Nominal values of variables
    *_y,                  ///< Temp   - Unknowns
    *_y0,                 ///< Temp   - Auxillary variables
    *_y_old,              ///< Temp   - Stores old solution
    *_y_new,              ///< Temp   - Stores new solution
    *_b,                  ///< Right hand side
    *_A,                  ///< Coefficients of linear system
    *_zeroVec,            ///< Zero vector
    *_fNominal;
};
/** @} */ // end of solverLinearSolver
