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
/*****************************************************************************/
/**
Allgemeine Klasse zur Kapselung der Parameter (Einstellungen) für einen nicht linearen Solver
Hier werden default-Einstellungen entsprechend der allgemeinen Simulations-
einstellungen gemacht, diese können überprüft und ev. Fehleinstellungen korrigiert
werden.
*****************************************************************************/

class INonLinSolverSettings
{
public:
  virtual ~INonLinSolverSettings() {};

  virtual long int getNewtMax() = 0;
  virtual void setNewtMax(long int) = 0;
  virtual double getRtol() = 0;
  virtual void setRtol(double) = 0;
  virtual double getAtol() = 0;
  virtual void setAtol(double) = 0;
  virtual double getDelta() = 0;
  virtual void setDelta(double) = 0;
  virtual void load(string) = 0;
  virtual void setContinueOnError(bool) = 0;
  virtual bool getContinueOnError() = 0;

  /// Global simulation settings
  virtual void setGlobalSettings(IGlobalSettings *settings)
  {
    _globalSettings = settings;
  }
  virtual IGlobalSettings* getGlobalSettings()
  {
    return _globalSettings;
  }
protected:
  IGlobalSettings *_globalSettings = NULL;
};
 /** @} */ // end of coreSolver
