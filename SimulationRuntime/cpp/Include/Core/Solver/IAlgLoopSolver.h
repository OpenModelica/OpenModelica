#pragma once
/** @addtogroup coreSolver
 *
 *  @{
 */
class IAlgLoop;
class IContinuous;

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

class IAlgLoopSolver
{
public:
  /// Enumeration to denote the status of iteration
  enum ITERATIONSTATUS
  {
    CONTINUE,
    SOLVERERROR,
    DONE,
  };

  virtual ~IAlgLoopSolver() {};

  /// (Re-) initialize the solver
  virtual void initialize() = 0;

  /// Solution of a (non-)linear system of equations
  virtual void solve() = 0;

  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus() = 0;
  virtual void stepCompleted(double time) = 0;
};
 /** @} */ // end of coreSolver