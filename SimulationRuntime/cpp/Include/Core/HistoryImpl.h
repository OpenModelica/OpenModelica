#pragma once

#ifdef ANALYZATION_MODE
#include <SimulationSettings/IGlobalSettings.h>
#include <DataExchange/IHistory.h>
#include <map>
#include <boost/range/adaptor/map.hpp>
#include <boost/range/algorithm/copy.hpp>
using std::map;
#endif

template< template <unsigned long,unsigned long,unsigned long>  class ResultsPolicy,unsigned long dim_1,unsigned long dim_2,unsigned long dim_3>
class HistoryImpl: public IHistory,
    public ResultsPolicy<dim_1,dim_2,dim_3>
{
public:

  HistoryImpl(IGlobalSettings& globalSettings)
  :ResultsPolicy<dim_1,dim_2,dim_3>((globalSettings.getEndTime()-globalSettings.getStartTime())/globalSettings.gethOutput(),globalSettings.getOutputPath(),globalSettings.getResultsFileName())
  ,_globalSettings(globalSettings)
  {

    }

    void setOutputs(map<unsigned int,string> var_outputs)
    {
        _var_outputs=var_outputs;


    }
    void init()
    {
        ResultsPolicy<dim_1,dim_2,dim_3>::init(_globalSettings.getOutputPath(),_globalSettings.getResultsFileName());
    }
    virtual void getOutputNames(vector<string>& output_names)
    {

        boost::copy(_var_outputs | boost::adaptors::map_values, std::back_inserter(output_names));

    }

    void getSimResults(const double time,ublas::vector<double>& v,ublas::vector<double>& dv)
    {
        ResultsPolicy<dim_1,dim_2,dim_3>::read(time,v,dv);

    }


    void getSimResults(ublas::matrix<double>& R,ublas::matrix<double>& dR)
    {

        ResultsPolicy<dim_1,dim_2,dim_3>::read(R,dR);

    }

    void getSimResults(ublas::matrix<double>& R,ublas::matrix<double>& dR,ublas::matrix<double>& Re)
    {

        ResultsPolicy<dim_1,dim_2,dim_3>::read(R,dR,Re);

    }

    virtual void getOutputResults(ublas::matrix<double>& Ro)
    {
        vector<unsigned int> ids;
        boost::copy(_var_outputs | boost::adaptors::map_keys, std::back_inserter(ids));
        ResultsPolicy<dim_1,dim_2,dim_3>::read(Ro,ids);
    }

    unsigned long getSize()
    {
        return  ResultsPolicy<dim_1,dim_2,dim_3>::size();
    }


    unsigned long getDimRe()
    {
        return dim_3;
    }


    unsigned long getDimdR()
    {
        return  dim_2;
    }



    unsigned long getDimR()
    {
        return  dim_1;
    }


    vector<double> getTimeEntries()
    {
        vector<double> time;
        ResultsPolicy<dim_1,dim_2,dim_3>::getTime(time);
        return time;
    }

    void clear()
    {
       ResultsPolicy<dim_1,dim_2,dim_3>::eraseAll();
    };
private:
    //map of indices of all output variables
    map<unsigned int,string> _var_outputs;
    IGlobalSettings& _globalSettings;

};
