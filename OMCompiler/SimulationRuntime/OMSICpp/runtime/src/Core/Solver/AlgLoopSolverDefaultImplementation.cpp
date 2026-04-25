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

/** @addtogroup coreSolver
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/Solver/FactoryExport.h>
#include <Core/Solver/AlgLoopSolverDefaultImplementation.h>


AlgLoopSolverDefaultImplementation::AlgLoopSolverDefaultImplementation()
    : _dimZeroFunc(-1)
      , _dimSys(-1)
      , _algloopVars(NULL)
      , _conditions0(NULL)
      , _conditions1(NULL)
{
}

AlgLoopSolverDefaultImplementation::~AlgLoopSolverDefaultImplementation()
{
    if (_algloopVars)
        delete [] _algloopVars;
    if (_conditions0)
        delete [] _conditions0;
    if (_conditions1)
        delete [] _conditions1;
}

bool* AlgLoopSolverDefaultImplementation::getConditionsWorkArray()
{
    if (_conditions0)
        return _conditions0;
    else
        ModelicaSimulationError(ALGLOOP_SOLVER, "algloop working arrays are not initialized");
}

bool* AlgLoopSolverDefaultImplementation::getConditions2WorkArray()
{
    if (_conditions1)
        return _conditions1;
    else
        ModelicaSimulationError(ALGLOOP_SOLVER, "algloop working arrays are not initialized");
}


double* AlgLoopSolverDefaultImplementation::getVariableWorkArray()
{
    if (_algloopVars)
        return _algloopVars;
    else
        ModelicaSimulationError(ALGLOOP_SOLVER, "algloop working arrays are not initialized");
}

void AlgLoopSolverDefaultImplementation::initialize(int dimZeroFunc, int dimSys)
{
    _dimZeroFunc = dimZeroFunc;
    if (_conditions0)
        delete [] _conditions0;
    if (_conditions1)
        delete [] _conditions1;
    _conditions0 = new bool[_dimZeroFunc];
    _conditions1 = new bool[_dimZeroFunc];
    _dimSys = dimSys;
    if (_algloopVars)
        delete [] _algloopVars;
    _algloopVars = new double[_dimSys];
    memset(_algloopVars, 0, _dimSys * sizeof(double));
}

/** @} */ // end of coreSolver
