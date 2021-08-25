#pragma once
#include "FactoryExport.h"
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>
#include <Core/System/ILinearAlgLoop.h>              // Interface to AlgLoo
#include <Core/System/INonLinearAlgLoop.h>              // Interface to AlgLoo
#include <Core/Solver/ILinearAlgLoopSolver.h>        // Export function from dll
#include <Core/Solver/ILinSolverSettings.h>
#include <Solver/UmfPack/UmfPackSettings.h>


class UmfPack : public ILinearAlgLoopSolver,  public AlgLoopSolverDefaultImplementation
{
public:
  UmfPack(ILinSolverSettings* settings,shared_ptr<ILinearAlgLoop> algLoop=shared_ptr<ILinearAlgLoop>());
  virtual ~UmfPack();

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
    ITERATIONSTATUS _iterationStatus;
    ILinSolverSettings *_umfpackSettings;
    shared_ptr<ILinearAlgLoop> _algLoop;

    double * _jacd;
    double * _rhs;
    double * _x,
           *_x_old,
           *_x_new;
    bool _firstuse;
};
