#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */

/*****************************************************************************/
/**

Abstract interface class for possibly hybrid (continous and discrete)
systems of equations in open modelica.

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
/// typedef for sparse matrices
typedef double* SparsityPattern;


class IMixedSystem
{
public:
  virtual ~IMixedSystem() {};
  /// Provide Jacobian
  virtual const matrix_t& getJacobian() = 0;
  virtual const matrix_t& getJacobian(unsigned int index)  = 0;
  virtual sparsematrix_t& getSparseJacobian() = 0;
  virtual sparsematrix_t& getSparseJacobian(unsigned int index)  = 0;

  virtual const matrix_t& getStateSetJacobian(unsigned int index) = 0;
  virtual const sparsematrix_t& getStateSetSparseJacobian(unsigned int index) = 0;

  /// Called to handle all  events occured at same time
  virtual bool handleSystemEvents(bool* events) = 0;

  //virtual void saveAll() = 0;
   virtual void getAlgebraicDAEVars(double* y) = 0;
   virtual void setAlgebraicDAEVars(const double* y) = 0;
   virtual void getResidual(double* f) = 0;

  virtual string getModelName() = 0;

  virtual void getAColorOfColumn(int* aSparsePatternColorCols, int size) = 0;
  virtual int getAMaxColors() = 0;

  // Copy the given IMixedSystem instance
  virtual IMixedSystem* clone() = 0;

  virtual bool isJacobianSparse() = 0;//true if getSparseJacobian is implemented and getJacobian is not, false if getJacobian is implemented and getSparseJacobian is not.
  virtual bool isAnalyticJacobianGenerated() = 0;//true if the flag --generateSymbolicJacobian is true, false if not.
  virtual  shared_ptr<ISimObjects> getSimObjects() = 0;
};
/** @} */ // end of coreSystem
