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
/** @addtogroup coreSimcontroller
 *
 *  @{
 */
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <string.h>
#include <boost/numeric/ublas/fwd.hpp>
#endif
*/

class ISimData
{
public:
  virtual ~ISimData()
  {

  };

  virtual ISimData* clone() = 0;

  virtual void Add(std::string key, shared_ptr<ISimVar> var) = 0;
  //Returns SimVar for a key
  virtual ISimVar* Get(std::string key) = 0;
  //Adds Results for an output var to simdata object
  virtual void addOutputResults(std::string name, ublas::vector<double> v) = 0;
  //Returns reference to results for an output var, when simData object is destroyed results are no longer valid
  virtual void getOutputResults(std::string name, ublas::vector<double>& v) = 0;
  //Clears all output var results
  virtual void clearResults() = 0;
  //Returns the time interval
  virtual void getTimeEntries(std::vector<double>& time_entries) = 0;
  virtual void addTimeEntries(std::vector<double> time_entries) = 0;
};
/** @} */ // end of coreSimcontroller
