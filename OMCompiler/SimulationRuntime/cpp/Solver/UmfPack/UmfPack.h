/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

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
