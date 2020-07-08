#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */
class ILinearAlgLoop;


/*****************************************************************************/
/**

Abstract interface class for numerical methods for the (possibly iterative)
solution of algebraic loops in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/

class ILinearAlgLoopSolver
{
public:
  /// Enumeration to denote the status of iteration
  enum ITERATIONSTATUS
  {
    CONTINUE,
    SOLVERERROR,
    DONE,
  };

  virtual ~ILinearAlgLoopSolver() {};

  /// (Re-) initialize the solver
  virtual void initialize() = 0;

  /// Solution of a (non-)linear system of equations
  virtual void solve() = 0;
  //solve for a single instance call
  virtual void solve(shared_ptr<ILinearAlgLoop> algLoop,bool first_solve = false) = 0;
  virtual bool* getConditionsWorkArray()=0;
  virtual bool* getConditions2WorkArray()=0;
  virtual double* getVariableWorkArray()=0;
  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus() = 0;
  virtual void stepCompleted(double time) = 0;
  virtual void restoreOldValues() = 0;
  virtual void restoreNewValues() = 0;
};
 /** @} */ // end of coreSolver