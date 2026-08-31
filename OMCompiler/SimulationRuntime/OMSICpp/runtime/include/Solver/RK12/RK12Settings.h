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
/** @addtogroup solverEuler
 *
 *  @{
 */
#include "FactoryExport.h"
#include <Core/Solver/SolverSettings.h>
#include <Solver/RK12/IRK12Settings.h>

/*****************************************************************************/
/**

Encapsulation of settings for euler solver

\date     October, 1st, 2008
\author


*/

class /*BOOST_EXTENSION_RK12Settings_DECL*/ RK12Settings : public IRK12Settings, public SolverSettings
{
public:
    RK12Settings(IGlobalSettings* globalSettings);
    /**
      Choise of solution method according to EULERMETHOD ([0,1,2,3,4,5]; default: 0)
      **/
    virtual unsigned int getRK12Method();
    virtual void setRK12Method(unsigned int);
    /**
     Choise of method for zero search according to ZEROSEARCHMETHOD ([0,1]; default: 0)
    */
    virtual unsigned int getZeroSearchMethod();
    virtual void setZeroSearchMethod(unsigned int);

    /**
    Determination of number of zeros in one intervall (used only for methods [2,3]) ([true,false]; default: false)
    */
    virtual bool getUseSturmSequence();
    virtual void setUseSturmSequence(bool);
    /**
    For implicit methods only. Choise between fixpoint and newton-iteration  kann eine Newtoniteration gewählt werden. ([false,true]; default: false = Fixpunktiteration)
    */
    virtual bool getUseNewtonIteration();
    virtual void setUseNewtonIteration(bool);
    /**
    Equidistant output(by interpolation polynominal) ([true,false]; default: false)
    */
    virtual bool getDenseOutput();
    virtual void setDenseOutput(bool);
    /**
Tolerance for newton iteration (used when _useNewtonIteration=true) (default: 1e-8)
*/
    virtual double getIterTol();
    virtual void setIterTol(double);
    //initializes the settings object by an xml file
    virtual void load(std::string xml_file);
private:
    int
        _method, ///< Choise of solution method according to EULERMETHOD ([0,1,2,3,4,5]; default: 0)
        _zeroSearchMethod; ///< Choise of method for zero search according to ZEROSEARCHMETHOD ([0,1]; default: 0)

    bool
        _denseOutput, ///< Equidistant output(by interpolation polynominal) ([true,false]; default: false)
        _useNewtonIteration,
        ///< For implicit methods only. Choise between fixpoint and newton-iteration  kann eine Newtoniteration gewählt werden. ([false,true]; default: false = Fixpunktiteration)
        _useSturmSequence;
    ///< Determination of number of zeros in one intervall (used only for methods [2,3]) ([true,false]; default: false)

    double
    _iterTol; ///< Tolerance for newton iteration (used when _useNewtonIteration=true) (default: 1e-8)
};

/** @} */ // end of solverEuler
