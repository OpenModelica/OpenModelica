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

/** @addtogroup solverEuler
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/RK12/RK12Settings.h>

RK12Settings::RK12Settings(IGlobalSettings* globalSettings)
: SolverSettings        (globalSettings)
, _method                (MULTIRATE)
, _zeroSearchMethod        (BISECTION)
, _denseOutput            (true)
, _useSturmSequence        (false)
, _useNewtonIteration    (false)
, _iterTol                (1e-8)
{
}


unsigned int RK12Settings::getRK12Method()
{
    return _method;
}
void RK12Settings::setRK12Method(unsigned int method)
{
    _method= method;
}

unsigned int RK12Settings::getZeroSearchMethod()
{
    return _zeroSearchMethod;
}
void RK12Settings::setZeroSearchMethod(unsigned int method )
{
    _zeroSearchMethod= method;
}

bool RK12Settings::getUseSturmSequence()
{
    return _useSturmSequence;
}
void RK12Settings::setUseSturmSequence(bool use)
{
    _useSturmSequence= use;
}

bool RK12Settings::getUseNewtonIteration()
{
    return _useNewtonIteration;
}
void RK12Settings::setUseNewtonIteration(bool use)
{
    _useNewtonIteration= use;
}

bool RK12Settings::getDenseOutput()
{
    return _denseOutput;
}
void RK12Settings::setDenseOutput(bool dense)
{
    _denseOutput = dense;
}

double RK12Settings::getIterTol()
{
    return _iterTol;
}
void RK12Settings::setIterTol(double tol)
{
    _iterTol = tol;
}

/**
initializes settings object by an xml file
*/
void RK12Settings::load(std::string xml_file)
{



}

/** @} */ // end of solverEuler
