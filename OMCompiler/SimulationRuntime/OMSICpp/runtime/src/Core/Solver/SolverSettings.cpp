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
#include <Core/Solver/SolverSettings.h>
#include <Core/SimulationSettings/IGlobalSettings.h>
//#include "../Interfaces/API.h"
#include <Core/Math/Constants.h>

SolverSettings::SolverSettings(IGlobalSettings* globalSettings)
    : _hInit(1e-3)
      , _hUpperLimit(1e-3)
      , _hLowerLimit(10 * UROUND)
      , _endTimeTol(1e-7)
      , _dRtol(1e-6)
      , _dAtol(1e-6)
      , _denseOutput(false)
{
    _globalSettings = globalSettings;
}

SolverSettings::~SolverSettings()
{
}

double SolverSettings::gethInit()
{
    return _hInit;
}

void SolverSettings::sethInit(double h)
{
    _hInit = h;
}

double SolverSettings::getATol()
{
    return _dAtol;
}

void SolverSettings::setATol(double atol)
{
    _dAtol = atol;
}

double SolverSettings::getRTol()
{
    return _dRtol;
}

void SolverSettings::setRTol(double rtol)
{
    _dRtol = rtol;
}

double SolverSettings::getLowerLimit()
{
    return _hLowerLimit;
}

void SolverSettings::setLowerLimit(double h)
{
    _hLowerLimit = h;
}

double SolverSettings::getUpperLimit()
{
    return _hUpperLimit;
}

void SolverSettings::setUpperLimit(double h)
{
    _hUpperLimit = h;
}

double SolverSettings::getEndTimeTol()
{
    return _endTimeTol;
}

void SolverSettings::setEndTimeTol(double tol)
{
    _endTimeTol = tol;
}

bool SolverSettings::getDenseOutput()
{
    return _denseOutput;
}

void SolverSettings::setDenseOutput(bool dense)
{
    _denseOutput = dense;
}

IGlobalSettings* SolverSettings::getGlobalSettings()
{
    return _globalSettings;
}

void SolverSettings::load(string)
{
}

/** @} */ // end of coreSolver
