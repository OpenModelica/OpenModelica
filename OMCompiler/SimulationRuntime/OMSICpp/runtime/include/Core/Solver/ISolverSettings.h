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
#include <Core/SimulationSettings/IGlobalSettings.h>

/** @addtogroup coreSolver
 *
 *  @{
 */


/*****************************************************************************/
/**

Abstract interface class for general solver settings.

\date     October, 1st, 2008
\author

*/


class ISolverSettings
{
public:
    virtual ~ISolverSettings()
    {
    };
    /// Initial step size (default: 1e-2)
    virtual double gethInit() = 0;
    virtual void sethInit(double) =0;
    /// Lower limit for step size during integration (default: should be machine precision)
    virtual double getLowerLimit() = 0;
    virtual void setLowerLimit(double) =0;
    /// Upper limit for step size during integration (default: _endTime-_startTime)
    virtual double getUpperLimit() = 0;
    virtual void setUpperLimit(double) = 0;
    /// Tolerance to reach _endTime (default: 1e-6)
    virtual double getEndTimeTol() = 0;
    virtual void setEndTimeTol(double) = 0;
    // DenseOut
    virtual bool getDenseOutput() = 0;
    virtual void setDenseOutput(bool) = 0;

    virtual double getATol() = 0;
    virtual void setATol(double) = 0;
    virtual double getRTol() = 0;
    virtual void setRTol(double) = 0;

    /// Global simulation settings
    virtual IGlobalSettings* getGlobalSettings() = 0;
    virtual void load(string) = 0;
};

/** @} */ // end of coreSolver
