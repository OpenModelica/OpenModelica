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
/** @addtogroup coreSystem
 *
 *  @{
 */

/*****************************************************************************/
/**

Abstract interface class for possibly hybrid (continous and discrete)
systems of equations in open modelica.


*/

/// typedef for sparse matrices
typedef double* SparsityPattern;


class IMixedSystem
{
public:
    virtual ~IMixedSystem()
    {
    };
    /// Provide Jacobian
    virtual const matrix_t& getJacobian() = 0;
    virtual const matrix_t& getJacobian(unsigned int index) = 0;
    virtual sparsematrix_t& getSparseJacobian() = 0;
    virtual sparsematrix_t& getSparseJacobian(unsigned int index) = 0;

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

    virtual bool isJacobianSparse() = 0;
    //true if getSparseJacobian is implemented and getJacobian is not, false if getJacobian is implemented and getSparseJacobian is not.
    virtual bool isAnalyticJacobianGenerated() = 0; //true if the flag --generateDynamicJacobian=symbolic, false if not.
    virtual shared_ptr<ISimObjects> getSimObjects() = 0;
};

/** @} */ // end of coreSystem
