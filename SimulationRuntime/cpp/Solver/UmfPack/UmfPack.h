#pragma once

#include <System/IAlgLoop.h>                // Interface to AlgLoo
#include <Solver/IAlgLoopSolver.h>        // Export function from dll
#include <Solver/ILinSolverSettings.h>
#include "UmfPackSettings.h"
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
};
