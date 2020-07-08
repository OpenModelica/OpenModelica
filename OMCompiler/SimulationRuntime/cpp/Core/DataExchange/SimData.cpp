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

SimData::SimData(SimData &instance)
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
    std::pair<string,shared_ptr<ISimVar> > elem(key,var);
    std::pair<Objects_type::iterator,bool> p = _sim_vars.insert(elem);
}

ISimVar* SimData::Get(string key)
{
    Objects_type::const_iterator iter =_sim_vars.find(key);

    //Prüfen ob das Simobjekt in Liste ist.
    if(iter!=_sim_vars.end())
    {
        shared_ptr<ISimVar> obj = iter->second;
        return obj.get();
    }
    else
        throw ModelicaSimulationError(DATASTORAGE,"There is no such sim variable " + key);
}

void  SimData::addOutputResults(string name,ublas::vector<double> v)
{
    std::pair<string,ublas::vector<double> > elem(name,v);
    std::pair<OutputResults_type::iterator,bool> p = _result_vars.insert(elem);
}

void SimData::getTimeEntries(vector<double>& time_entries)
{
    time_entries = omcpp::ref(_time_entries);
}

void SimData::addTimeEntries(vector<double> time_entries)
{
    _time_entries = time_entries;
}

void  SimData::destroy()
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

void  SimData::getOutputResults(string name,ublas::vector<double>& v)
{
    OutputResults_type::const_iterator iter =_result_vars.find(name);

    //Prüfen ob die Ergebnisse  in Liste ist.
    if(iter!=_result_vars.end())
    {

        v = omcpp::ref(iter->second);
    }
    else
        throw ModelicaSimulationError(DATASTORAGE,"There is no such output variable " + name);
}

extern "C" ISimData* createSimDataAnalyzation()
{
  return new SimData();
}
/** @} */ // end of dataexchange
