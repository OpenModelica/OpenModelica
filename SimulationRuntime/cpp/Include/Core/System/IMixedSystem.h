#pragma once
#include <Core/Modelica.h>
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
typedef uBlas::compressed_matrix<double, uBlas::row_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > SparseMatrix;

class IMixedSystem
{
public:
  virtual ~IMixedSystem() {};
  /// Provide Jacobian
  virtual void getJacobian(SparseMatrix& matrix) = 0;
  virtual void getStateSetJacobian(unsigned int index, SparseMatrix& matrix) = 0;
  /// Called to handle all  events occured at same time
  virtual bool handleSystemEvents(bool* events) = 0;

  //virtual void saveAll() = 0;

  virtual string getModelName() = 0;

  virtual void getAColorOfColumn(int* aSparsePatternColorCols, int size) = 0;
  virtual int getAMaxColors() = 0;
};