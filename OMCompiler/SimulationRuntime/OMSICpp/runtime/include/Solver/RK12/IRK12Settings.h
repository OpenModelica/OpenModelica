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
/** @addtogroup solverRK12
 *
 *  @{
 */


/*****************************************************************************/
/**

Encapsulation of settings for RK12 solver

\date     October, 1st, 2008
\author


*/

class IRK12Settings
{
public:
    /// Enum to choose the integration method
    enum RK12METHOD
    {
        STEPSIZECONTROL = 0,
        ///< Explicit RK12
        MULTIRATE = 1,
        ///< Implicit RK12
    };

    /// Enum to choose the method for zero search
    enum ZEROSEARCHMETHOD
    {
        NO_ZERO_SEARCH = 0,
        ///< Ignore zero functions
        BISECTION = 1,
        ///< Bisection method
        LINEAR_INTERPOLATION = 2,
        ///< Linear interpolation
    };

    virtual ~IRK12Settings()
    {
    };

    /**
    Choise of solution method according to RK12METHOD ([0,1,2,3,4,5]; default: 0)
    **/
    virtual unsigned int getRK12Method() =0;
    virtual void setRK12Method(unsigned int) =0;
    /**
     Choise of method for zero search according to ZEROSEARCHMETHOD ([0,1]; default: 0)
    */
    virtual unsigned int getZeroSearchMethod() =0;
    virtual void setZeroSearchMethod(unsigned int) =0;

    /**
    Determination of number of zeros in one intervall (used only for methods [2,3]) ([true,false]; default: false)
    */
    virtual bool getUseSturmSequence() =0;
    virtual void setUseSturmSequence(bool) =0;
    /**
    For implicit methods only. Choise between fixpoint and newton-iteration  kann eine Newtoniteration gewählt werden. ([false,true]; default: false = Fixpunktiteration)
    */
    virtual bool getUseNewtonIteration() =0;
    virtual void setUseNewtonIteration(bool) =0;
    /**
    Equidistant output(by interpolation polynominal) ([true,false]; default: false)
    */
    virtual bool getDenseOutput() =0;
    virtual void setDenseOutput(bool) =0;
    /**
Tolerance for newton iteration (used when _useNewtonIteration=true) (default: 1e-8)
*/
    virtual double getIterTol() =0;
    virtual void setIterTol(double) =0;
    virtual void load(std::string xml_file) =0;
};

/** @} */ // end of solverRK12
