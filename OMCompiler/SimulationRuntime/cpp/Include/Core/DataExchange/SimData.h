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
