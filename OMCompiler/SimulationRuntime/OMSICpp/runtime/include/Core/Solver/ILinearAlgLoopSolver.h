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
/** @addtogroup coreSolver
 *
 *  @{
 */
class ILinearAlgLoop;


/*****************************************************************************/
/**

Abstract interface class for numerical methods for the (possibly iterative)
solution of algebraic loops in open modelica.

\date     October, 1st, 2008
\author

*/


class ILinearAlgLoopSolver
{
public:
    /// Enumeration to denote the status of iteration
    enum ITERATIONSTATUS
    {
        CONTINUE,
        SOLVERERROR,
        DONE,
    };

    virtual ~ILinearAlgLoopSolver()
    {
    };

    /// (Re-) initialize the solver
    virtual void initialize() = 0;

    /// Solution of a (non-)linear system of equations
    virtual void solve() = 0;
    //solve for a single instance call
    virtual void solve(shared_ptr<ILinearAlgLoop> algLoop, bool first_solve = false) = 0;
    virtual bool* getConditionsWorkArray() =0;
    virtual bool* getConditions2WorkArray() =0;
    virtual double* getVariableWorkArray() =0;
    /// Returns the status of iteration
    virtual ITERATIONSTATUS getIterationStatus() = 0;
    virtual void stepCompleted(double time) = 0;
    virtual void restoreOldValues() = 0;
    virtual void restoreNewValues() = 0;
};

/** @} */ // end of coreSolver
