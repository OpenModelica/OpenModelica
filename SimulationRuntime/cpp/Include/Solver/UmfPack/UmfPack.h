#pragma once

#include <Core/System/IAlgLoop.h>                // Interface to AlgLoo
#include <Core/Solver/IAlgLoopSolver.h>        // Export function from dll
#include <Core/Solver/ILinSolverSettings.h>
#include <Solver/UmfPack/UmfPackSettings.h>
#include <boost/shared_ptr.hpp>
#include <boost/weak_ptr.hpp>
#include <boost/numeric/ublas/vector.hpp>
#include <boost/numeric/ublas/matrix.hpp>
#include <boost/numeric/ublas/matrix_sparse.hpp>
#include <cstring>
#include <iostream>

class UmfPack : public IAlgLoopSolver
{
public:
  UmfPack(IAlgLoop* algLoop,ILinSolverSettings* settings);
  virtual ~UmfPack();

    virtual void initialize();

    /// Solution of a (non-)linear system of equations
    virtual void solve();

    /// Returns the status of iteration
    virtual ITERATIONSTATUS getIterationStatus();
    virtual void stepCompleted(double time);

private:
    ITERATIONSTATUS _iterationStatus;
    ILinSolverSettings *_umfpackSettings;
    IAlgLoop *_algLoop;
    boost::shared_ptr<matrix_t> _jacs;
    double * _jacd;
    double * _rhs;
    double * _x;
    bool _firstuse;
};
