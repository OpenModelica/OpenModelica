#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

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

class IAlgLoopSolverFactory
{
public:
  IAlgLoopSolverFactory() {};
  virtual ~IAlgLoopSolverFactory() {};
  virtual  shared_ptr<IAlgLoopSolver> createLinearAlgLoopSolver(ILinearAlgLoop* algLoop) = 0;
  virtual  shared_ptr<IAlgLoopSolver> createNonLinearAlgLoopSolver(INonLinearAlgLoop* algLoop) = 0;
};
/** @} */ // end of coreSystem
