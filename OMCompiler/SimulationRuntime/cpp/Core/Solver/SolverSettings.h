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

Encapsulation of general solver settings.

\date     October, 1st, 2008
\author


*/

class BOOST_EXTENSION_SOLVERSETTINGS_DECL SolverSettings : public ISolverSettings
{
public:
  SolverSettings(IGlobalSettings* globalSettings);
  virtual ~SolverSettings();
  /// Initial step size (default: 1e-2)
  virtual double gethInit();
  virtual void sethInit(double);
  /// Lower limit for step size during integration (default: should be machine precision)
  virtual double getLowerLimit();
  virtual void setLowerLimit(double);
  /// Upper limit for step size during integration (default: _endTime-_startTime)
  virtual double getUpperLimit();
  virtual void setUpperLimit(double);
  /// Tolerance to reach _endTime (default: 1e-6)
  virtual double getEndTimeTol();
  virtual void setEndTimeTol(double);

  //dense Output
  virtual bool getDenseOutput();
  virtual void setDenseOutput(bool);

  virtual double getATol();
  virtual void setATol(double);
  virtual double getRTol();
  virtual void setRTol(double);

  ///  Global simulation settings
  virtual IGlobalSettings* getGlobalSettings();
  virtual void load(string);

private:
  double
    _hInit,             ///< Initial step size (default: 1e-2)
    _hLowerLimit,       ///< Lower limit for step size during integration (default: should be machine precision)
    _hUpperLimit,       ///< Upper limit for step size during integration (default: _endTime-_startTime)
    _endTimeTol,        ///< Tolerance to reach _endTime (default: 1e-6)
    _dRtol,
    _dAtol;
  IGlobalSettings*
    _globalSettings;    ///< Global simulation settings

  bool
    _denseOutput;
};
 /** @} */ // end of coreSolver
