#pragma once
//#include <DataExchange/IHistory.h>
#include <boost/numeric/ublas/matrix_sparse.hpp>
namespace uBlas = boost::numeric::ublas;

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
typedef uBlas::compressed_matrix<double, uBlas::column_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > SparseMatrix;

class IMixedSystem 
{
public:
   
  virtual ~IMixedSystem()  {};
   /// Provide Jacobian
  virtual void getJacobian(SparseMatrix& matrix) = 0;
   /// Called to handle all  events occured at same time 
  virtual bool handleSystemEvents(bool* events) = 0;
   //Saves all variables before an event is handled, is needed for the pre, edge and change operator
  virtual void saveAll() = 0;
  

};
