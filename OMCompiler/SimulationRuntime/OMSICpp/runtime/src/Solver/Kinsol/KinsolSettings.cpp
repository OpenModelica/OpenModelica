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

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
/** @addtogroup solverKinsol
 *
 *  @{
 */

#include <Solver/Kinsol/KinsolSettings.h>

KinsolSettings::KinsolSettings()
    : _iNewt_max(700)
      , _dRtol(1e-12)
      , _dAtol(1.0)
      , _dDelta(0.9)
      , _continueOnError(false)
{
};
/*max. Anzahl an Newtonititerationen pro Schritt (default: 25)*/
long int KinsolSettings::getNewtMax()
{
    return _iNewt_max;
}

void KinsolSettings::setNewtMax(long int max)
{
    _iNewt_max = max;
}

/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
double KinsolSettings::getRtol()
{
    return _dRtol;
}

void KinsolSettings::setRtol(double t)
{
    _dRtol = t;
}

/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
double KinsolSettings::getAtol()
{
    return _dAtol;
}

void KinsolSettings::setAtol(double t)
{
    _dAtol = t;
}

/*Dämpfungsfaktor (default: 0.9)*/
double KinsolSettings::getDelta()
{
    return _dDelta;
}

void KinsolSettings::setDelta(double t)
{
    _dDelta = t;
}

void KinsolSettings::load(string)
{
}

void KinsolSettings::setContinueOnError(bool value)
{
    _continueOnError = value;
}

bool KinsolSettings::getContinueOnError()
{
    return _continueOnError;
}

/** @} */ // end of solverKinsol
