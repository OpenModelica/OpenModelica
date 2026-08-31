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

/** @addtogroup dataexchange
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/DataExchange/SimData.h>

SimData::SimData(void)
{
}

SimData::SimData(SimData& instance)
{
}

SimData::~SimData(void)
{
}

ISimData* SimData::clone()
{
    return new SimData(*this);
}

void SimData::Add(string key, shared_ptr<ISimVar> var)
{
    std::pair<string, shared_ptr<ISimVar>> elem(key, var);
    std::pair<Objects_type::iterator, bool> p = _sim_vars.insert(elem);
}

ISimVar* SimData::Get(string key)
{
    Objects_type::const_iterator iter = _sim_vars.find(key);

    //Prüfen ob das Simobjekt in Liste ist.
    if (iter != _sim_vars.end())
    {
        shared_ptr<ISimVar> obj = iter->second;
        return obj.get();
    }
    else
        throw ModelicaSimulationError(DATASTORAGE, "There is no such sim variable " + key);
}

void SimData::addOutputResults(string name, ublas::vector<double> v)
{
    std::pair<string, ublas::vector<double>> elem(name, v);
    std::pair<OutputResults_type::iterator, bool> p = _result_vars.insert(elem);
}

void SimData::getTimeEntries(vector<double>& time_entries)
{
    time_entries = omcpp::ref(_time_entries);
}

void SimData::addTimeEntries(vector<double> time_entries)
{
    _time_entries = time_entries;
}

void SimData::destroy()
{
    delete this;
}

void SimData::clearResults()
{
    _result_vars.clear();
    _time_entries.clear();
}

void SimData::clearVars()
{
    _sim_vars.clear();
}

void SimData::getOutputResults(string name, ublas::vector<double>& v)
{
    OutputResults_type::const_iterator iter = _result_vars.find(name);

    //Prüfen ob die Ergebnisse  in Liste ist.
    if (iter != _result_vars.end())
    {
        v = omcpp::ref(iter->second);
    }
    else
        throw ModelicaSimulationError(DATASTORAGE, "There is no such output variable " + name);
}

extern "C" ISimData* createSimDataAnalyzation()
{
    return new SimData();
}

/** @} */ // end of dataexchange
