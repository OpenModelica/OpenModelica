#pragma once
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <Core/SimulationSettings//IGlobalSettings.h>
#include <Core/DataExchange/IHistory.h>
#include <map>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>
using std::map;
#endif
*/
 /** @defgroup core Core
 *  Core module of cpp runtime
 *
 *  @{
 */
template< template <size_t,size_t,size_t,size_t>  class ResultsPolicy,size_t dim_1, size_t dim_2,size_t dim_3,size_t dim_4>
class HistoryImpl : public IHistory,
  public ResultsPolicy<dim_1,dim_2,dim_3,dim_4>
{
public:
  HistoryImpl(IGlobalSettings& globalSettings)
    : ResultsPolicy<dim_1,dim_2,dim_3,dim_4>((globalSettings.getEndTime()-globalSettings.getStartTime())/globalSettings.gethOutput(),globalSettings.getOutputPath(),globalSettings.getResultsFileName())
    , _globalSettings(globalSettings)
  {
  }

  virtual ~HistoryImpl()
  {

  }

  /*
  void setOutputs(map<unsigned int,string> var_outputs)
  {
    _var_outputs=var_outputs;
  }
  */

  void init()
  {
    ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::init(_globalSettings.getOutputPath(), _globalSettings.getResultsFileName());
  }

  virtual void getOutputNames(vector<string>& output_names)
  {
    //boost::copy(_var_outputs | boost::adaptors::map_values, std::back_inserter(output_names));
    output_names = ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::_var_outputs;
  }

  void getSimResults(const double time, ublas::vector<double>& v, ublas::vector<double>& dv)
  {
    ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::read(time,v,dv);
  }

  void getSimResults(ublas::matrix<double>& R, ublas::matrix<double>& dR)
  {
    ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::read(R,dR);
  }

  void getSimResults(ublas::matrix<double>& R, ublas::matrix<double>& dR, ublas::matrix<double>& Re)
  {
    ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::read(R, dR, Re);
  }

  virtual void getOutputResults(ublas::matrix<double>& Ro)
  {
    //vector<unsigned int> ids;
    //boost::copy(_var_outputs | boost::adaptors::map_keys, std::back_inserter(ids));
    ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::read(Ro);
  }

  unsigned long getSize()
  {
    return ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::size();
  }

  unsigned long getDimRe()
  {
    return dim_3;
  }

  unsigned long getDimdR()
  {
    return dim_2;
  }

  unsigned long getDimR()
  {
    return dim_1;
  }

  vector<double> getTimeEntries()
  {
    vector<double> time;
    ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::getTime(time);
    return time;
  }

  void clear()
  {
    ResultsPolicy<dim_1,dim_2,dim_3,dim_4>::eraseAll();
  };

private:
  //map of indices of all output variables
  //map<unsigned int,string> _var_outputs;

  IGlobalSettings& _globalSettings;
};
/** @} */ // end of core
