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

/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Newton/NewtonSettings.h>

NewtonSettings::NewtonSettings()
  : _iNewt_max                 (50)
  , _dRtol                     (1e-8)
  , _dAtol                     (1e-8)
  , _dDelta                    (1)
  , _continueOnError           (false)
{
}

NewtonSettings::~NewtonSettings()
{
}

/*max. Anzahl an Newtonititerationen pro Schritt (default: 50)*/
long int NewtonSettings::getNewtMax()
{
  return _iNewt_max;
}

void NewtonSettings::setNewtMax(long int max)
{
  _iNewt_max = max;
}

/* Relative Toleranz für die Newtoniteration (default: 1e-6)*/
double NewtonSettings::getRtol()
{
  return _dRtol;
}

void NewtonSettings::setRtol(double t)
{
  _dRtol=t;
}

/*Absolute Toleranz für die Newtoniteration (default: 1e-6)*/
double NewtonSettings::getAtol()
{
  return _dAtol;
}

void NewtonSettings::setAtol(double t)
{
  _dAtol =t;
}

/*Dämpfungsfaktor (default: 0.9)*/
double NewtonSettings::getDelta()
{
  return _dDelta;
}

void NewtonSettings::setDelta(double t)
{
  _dDelta = t;
}

void NewtonSettings::load(string)
{
}

void NewtonSettings::setGlobalSettings(IGlobalSettings *settings)
{
   _globalSettings = settings;
   _dAtol = max(settings->getTolerance() * 1e-2, 1e-12);
   _dRtol = _dAtol;
}

void NewtonSettings::setContinueOnError(bool value)
{
  _continueOnError = value;
}

bool NewtonSettings::getContinueOnError()
{
  return _continueOnError;
}

/** @} */ // end of solverNewton
