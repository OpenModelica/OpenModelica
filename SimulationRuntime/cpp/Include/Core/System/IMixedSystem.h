#pragma once
#include <DataExchange/IHistory.h>
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
typedef double* SparcityPattern;
typedef uBlas::compressed_matrix<double, uBlas::column_major, 0, uBlas::unbounded_array<int>, uBlas::unbounded_array<double> > SparseMatrix;

class IMixedSystem
{
public:

    /// Enumeration to control the output
    enum OUTPUT
    {
        UNDEF_OUTPUT    =    0x00000000,

        WRITE            =    0x00000001,            ///< Store current position of curser and write out current results
        RESET            =    0x00000002,            ///< Reset curser position
        OVERWRITE        =    0x00000003,            ///< RESET|WRITE

        HEAD_LINE        =    0x00000010,            ///< Write out head line
        RESULTS            =    0x00000020,            ///< Write out results
        SIMINFO            =    0x00000040            ///< Write out simulation info (e.g. number of steps)
    };

    virtual ~IMixedSystem()    {};
    /// Output routine (to be called by the solver after every successful integration step)
    virtual void writeOutput(const OUTPUT command = UNDEF_OUTPUT) = 0;
      /// Provide Jacobian
    virtual void giveJacobian(SparseMatrix& matrix) = 0;
    /// Provide mass matrix
    virtual void giveMassMatrix(SparseMatrix& matrix) = 0;
    /// Provide global constraint jacobian
    virtual void giveConstraint(SparseMatrix matrix) = 0;
    virtual IHistory* getHistory()=0;
    /// Called to handle all  events occured at same time
    virtual bool handleSystemEvents(bool* events) = 0;
     //Saves all variables before an event is handled, is needed for the pre, edge and change operator
    virtual void saveAll() = 0;

};
