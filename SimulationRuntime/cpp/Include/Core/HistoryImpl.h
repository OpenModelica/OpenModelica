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
template< class ResultsPolicy >
class HistoryImpl : public IHistory,
  public ResultsPolicy
{
public:
  HistoryImpl(IGlobalSettings& globalSettings,size_t dim)
    : ResultsPolicy((globalSettings.getEndTime()-globalSettings.getStartTime())/globalSettings.gethOutput(),globalSettings.getOutputPath(),globalSettings.getResultsFileName())
    , _globalSettings(globalSettings)
    , _dim(dim)
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
    ResultsPolicy::init(_globalSettings.getOutputPath(), _globalSettings.getResultsFileName(),_dim);
  }

  virtual void getOutputNames(vector<string>& output_names)
  {
    //boost::copy(_var_outputs | boost::adaptors::map_values, std::back_inserter(output_names));
    output_names = ResultsPolicy::_var_outputs;
  }

  void getSimResults(const double time, ublas::vector<double>& v, ublas::vector<double>& dv)
  {
    ResultsPolicy::read(time,v,dv);
  }

  void getSimResults(ublas::matrix<double>& R, ublas::matrix<double>& dR)
  {
    ResultsPolicy::read(R,dR);
  }

  void getSimResults(ublas::matrix<double>& R, ublas::matrix<double>& dR, ublas::matrix<double>& Re)
  {
    ResultsPolicy::read(R, dR, Re);
  }

  virtual void getOutputResults(ublas::matrix<double>& Ro)
  {
    //vector<unsigned int> ids;
    //boost::copy(_var_outputs | boost::adaptors::map_keys, std::back_inserter(ids));
    ResultsPolicy::read(Ro);
  }

  unsigned long getSize()
  {
    return ResultsPolicy::size();
  }

  unsigned long getDimRe()
  {
    throw ModelicaSimulationError(DATASTORAGE,"getDimRe not implemented yet");
  }

  unsigned long getDimdR()
  {
    throw ModelicaSimulationError(DATASTORAGE,"getDimdR not implemented yet");
  }

  unsigned long getDimR()
  {
    throw ModelicaSimulationError(DATASTORAGE,"getDimR not implemented yet");
  }

  vector<double> getTimeEntries()
  {
    vector<double> time;
    ResultsPolicy::getTime(time);
    return time;
  }

  void clear()
  {
    ResultsPolicy::eraseAll();
  };

private:
  //map of indices of all output variables
  //map<unsigned int,string> _var_outputs;

  IGlobalSettings& _globalSettings;
  size_t _dim;
};
/** @} */ // end of core
