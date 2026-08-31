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
/** @addtogroup dataexchange
 *
 *  @{
 */

#include <Core/SimController/ISimData.h>


class SimData : public ISimData
{
public:
  SimData(void);
  SimData(SimData &instance);
  virtual ~SimData(void);

  virtual ISimData* clone();
  virtual void  Add(string key, shared_ptr<ISimVar> var);
  virtual ISimVar* Get(string key);
  virtual void addOutputResults(string name, ublas::vector<double> v);
  virtual void getOutputResults(string name, ublas::vector<double>& v);
  virtual void clearResults();
  virtual void clearVars();
  virtual void getTimeEntries(vector<double>& time_entries);
  virtual void addTimeEntries(vector<double> time_entries);
  virtual void destroy();

private:
  typedef map<string,shared_ptr<ISimVar> > Objects_type;
  typedef map<string,ublas::vector<double> > OutputResults_type;

  Objects_type _sim_vars;
  OutputResults_type _result_vars;
  vector<double> _time_entries;
};
/** @} */ // end of dataexchange
